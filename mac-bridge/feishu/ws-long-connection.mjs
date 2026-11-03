#!/usr/bin/env node
/**
 * 飞书 WS 长连接入口（收口桥 · 飞书）
 * - 凭证/配置读本机 ~/.config/mac-bridge/（或 MAC_BRIDGE_CONFIG）
 * - 私聊或群聊真正 @bot → OnIt 占坑，并 POST 飞书助手唤醒 webhook（config 键 steward_webhook）
 * - 群聊未 @ 不唤醒
 * - 可选异步 ingest（config.qa_ingest）
 * 可跑在 Linux / macOS / Windows 常开主机。
 */
import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import * as Lark from '@larksuiteoapi/node-sdk';
import { loadConfig, readTextFile, ensureDir, expandHome } from '../lib/config.mjs';
import { forwardWebhook } from '../lib/forward.mjs';

const cfg = loadConfig();
const feishu = cfg.feishu || {};
if (!feishu.app_id) throw new Error('feishu.app_id missing in config');

const APP_ID = feishu.app_id;
const APP_SECRET = readTextFile(feishu.app_secret_file, { required: true });
const inboxDir = ensureDir(feishu.inbox_dir || '~/.config/mac-bridge/data');
const INBOX = path.join(inboxDir, 'inbox.jsonl');

const BOT_OPEN_IDS = new Set();
try {
  const botFile = feishu.bot_open_id_file || '~/.config/mac-bridge/bot_open_id';
  const raw = readTextFile(botFile);
  for (const line of raw.split(/\s+/)) {
    if (line.startsWith('ou_')) BOT_OPEN_IDS.add(line.trim());
  }
} catch {}

const BOT_NAME_RE = new RegExp(feishu.bot_name_re || '飞书助手|Grok Bot|bot管家');

// 可选：仅作记录；唤醒以真正 @bot / 私聊为准。勿在仓内写真实群 ID。
const FOLLOW_CHAT_IDS = new Set((feishu.follow_chat_ids || []).filter(Boolean));

function ingestQa(rec) {
  const qa = feishu.qa_ingest || {};
  if (!qa.enabled) return;
  const script = expandHome(qa.script || '');
  if (!script || !fs.existsSync(script)) {
    console.error('qa ingest skipped: script missing', script);
    return;
  }
  const env = { ...process.env };
  if (qa.db) env.FEISHU_QA_DB = expandHome(qa.db);
  try {
    const child = spawn('python3', [script, 'from-event'], {
      stdio: ['pipe', 'ignore', 'pipe'],
      env,
    });
    child.stdin.write(JSON.stringify(rec));
    child.stdin.end();
    child.on('error', (e) => console.error('qa ingest spawn failed', e.message));
    child.stderr.on('data', (d) => {
      const s = d.toString().trim();
      if (s) console.error('qa ingest', s.slice(0, 200));
    });
  } catch (e) {
    console.error('qa ingest failed', e.message);
  }
}

let cachedToken = { token: '', exp: 0 };

async function tenantToken() {
  const now = Date.now();
  if (cachedToken.token && cachedToken.exp > now + 60_000) return cachedToken.token;
  const res = await fetch('https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ app_id: APP_ID, app_secret: APP_SECRET }),
  });
  const j = await res.json();
  if (!j.tenant_access_token) throw new Error(`token failed: ${JSON.stringify(j).slice(0, 200)}`);
  cachedToken = {
    token: j.tenant_access_token,
    exp: now + (Number(j.expire) || 7200) * 1000,
  };
  return cachedToken.token;
}

async function prefetchToken(reason = 'start') {
  try {
    const t0 = Date.now();
    await tenantToken();
    console.log('prefetch token ok', reason, `${Date.now() - t0}ms`);
  } catch (e) {
    console.error('prefetch token failed', reason, e.message);
  }
}

prefetchToken('boot');
setInterval(() => prefetchToken('refresh'), 50 * 60 * 1000).unref?.();

async function ackOnIt(messageId) {
  if (!messageId) return;
  try {
    const token = await tenantToken();
    const res = await fetch(`https://open.feishu.cn/open-apis/im/v1/messages/${messageId}/reactions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ reaction_type: { emoji_type: 'OnIt' } }),
    });
    const j = await res.json().catch(() => ({}));
    if (j.code !== 0) console.error('ack OnIt failed', messageId, j.code, j.msg);
    else console.log('ack OnIt', messageId);
  } catch (e) {
    console.error('ack OnIt error', e.message);
  }
}

function appendInbox(rec) {
  const withTs = { ...rec, received_at: new Date().toISOString() };
  fs.appendFileSync(INBOX, JSON.stringify(withTs) + '\n');
  ingestQa(withTs);
}

function shouldHandle(data) {
  try {
    const msg = data.message || {};
    const mentions = msg.mentions || [];
    let text = '';
    try {
      text = JSON.parse(msg.content || '{}').text || '';
    } catch {
      text = msg.content || '';
    }
    const mentionedBot = mentions.some((m) => {
      const oid = m.id?.open_id || m.id || '';
      const name = m.name || '';
      if (BOT_OPEN_IDS.has(oid)) return true;
      if (typeof oid === 'string' && oid.includes(APP_ID)) return true;
      if (BOT_NAME_RE.test(name)) return true;
      return false;
    });
    return {
      text,
      atBot: mentionedBot,
      chat_id: msg.chat_id,
      message_id: msg.message_id,
      msg_type: msg.message_type,
      followed: FOLLOW_CHAT_IDS.has(msg.chat_id),
    };
  } catch (e) {
    return { text: '', atBot: false, error: String(e) };
  }
}

const wsClient = new Lark.WSClient({
  appId: APP_ID,
  appSecret: APP_SECRET,
  loggerLevel: Lark.LoggerLevel.info,
});

console.log('mac-bridge feishu WS starting… config=', cfg.__config_path, 'inbox=', INBOX);
wsClient.start({
  eventDispatcher: new Lark.EventDispatcher({}).register({
    'im.message.receive_v1': async (data) => {
      const parsed = shouldHandle(data);
      const rec = { type: 'im.message.receive_v1', parsed, raw: data };
      appendInbox(rec);
      const chatType = data?.message?.chat_type || '';
      const isP2p = chatType === 'p2p';
      const shouldWake = isP2p || parsed.atBot;
      const t0 = Date.now();
      console.log('inbox', parsed.chat_id, chatType, parsed.atBot, (parsed.text || '').slice(0, 80));
      if (shouldWake) {
        const ack = ackOnIt(parsed.message_id).then(() => {
          console.log('ack OnIt done', parsed.message_id, `${Date.now() - t0}ms`);
        });
        const wake = Promise.resolve()
          .then(() =>
            forwardWebhook(
              feishu.steward_webhook,
              {
                source: 'mac-bridge-feishu-ws',
                chat_type: chatType,
                ...parsed,
                raw_event_id: data?.event_id,
                bridge_received_at: new Date().toISOString(),
              },
              { label: 'feishu-assistant-webhook' },
            ),
          )
          .then((r) => {
            console.log('webhook fired', parsed.message_id, `${Date.now() - t0}ms`, r?.status || r?.skipped || '');
          })
          .catch((e) => console.error('webhook error', e.message));
        void Promise.allSettled([ack, wake]);
      }
    },
    'im.chat.member.bot.added_v1': async (data) => {
      appendInbox({ type: 'im.chat.member.bot.added_v1', raw: data });
    },
    'im.chat.member.bot.deleted_v1': async (data) => {
      appendInbox({ type: 'im.chat.member.bot.deleted_v1', raw: data });
    },
  }),
});
