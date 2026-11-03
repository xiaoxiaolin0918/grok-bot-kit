#!/usr/bin/env node
/**
 * Codeup/云效 HTTP 收口（收口桥 · 云效）
 * - 本机监听 listen_host:listen_port
 * - 校验可选 shared_secret（Header: X-Mac-Bridge-Secret / X-Codeup-Token / X-Gitlab-Token，或 ?secret=）
 * - POST 到质量监管 webhook（本机配置文件）
 *
 * 默认只绑 127.0.0.1；用 frp / cloudflared / ngrok / 反代暴露公网。
 * 桥落地并自测通后再改 Codeup 远端 Webhook。
 */
import http from 'http';
import { loadConfig, readTextFile } from '../lib/config.mjs';
import { forwardWebhook } from '../lib/forward.mjs';

const cfg = loadConfig();
const yx = cfg.yunxiao || {};
const host = yx.listen_host || '127.0.0.1';
const port = Number(yx.listen_port || 8787);
const routePath = yx.path || '/yunxiao/codeup';
const expectedSecret = yx.shared_secret_file
  ? readTextFile(yx.shared_secret_file)
  : '';

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function unauthorized(res, msg) {
  res.writeHead(401, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ ok: false, error: msg }));
}

function ok(res, body) {
  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

function authKeysPresent(req, url) {
  return {
    has_mac_bridge: Boolean(req.headers['x-mac-bridge-secret']),
    has_codeup: Boolean(req.headers['x-codeup-token']),
    has_gitlab: Boolean(req.headers['x-gitlab-token']),
    has_query_secret: Boolean(url.searchParams.get('secret')),
    ua: (req.headers['user-agent'] || '').slice(0, 80),
    event: req.headers['x-codeup-event'] || req.headers['x-gitlab-event'] || '',
  };
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${host}:${port}`);
  if (req.method === 'GET' && url.pathname === '/healthz') {
    return ok(res, { ok: true, service: 'mac-bridge-yunxiao', path: routePath });
  }
  if (req.method !== 'POST' || url.pathname !== routePath) {
    console.log(JSON.stringify({ t: new Date().toISOString(), kind: 'miss', method: req.method, path: url.pathname }));
    res.writeHead(404, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ ok: false, error: 'not found' }));
  }

  const present = authKeysPresent(req, url);
  if (expectedSecret) {
    const hdr = req.headers['x-mac-bridge-secret'] || '';
    // Codeup「Secret Token」发在 X-Codeup-Token（不是 Authorization）
    const codeupTok = req.headers['x-codeup-token'] || '';
    const gitlabTok = req.headers['x-gitlab-token'] || '';
    const q = url.searchParams.get('secret') || '';
    if (
      hdr !== expectedSecret &&
      codeupTok !== expectedSecret &&
      gitlabTok !== expectedSecret &&
      q !== expectedSecret
    ) {
      console.log(JSON.stringify({ t: new Date().toISOString(), kind: '401', ...present }));
      return unauthorized(res, 'bad secret');
    }
  }
  console.log(JSON.stringify({ t: new Date().toISOString(), kind: 'accept', ...present }));

  let rawBuf;
  try {
    rawBuf = await readBody(req);
  } catch (e) {
    res.writeHead(400, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ ok: false, error: e.message }));
  }

  let parsed;
  const rawText = rawBuf.toString('utf8') || '{}';
  try {
    parsed = JSON.parse(rawText);
  } catch {
    parsed = { _raw: rawText };
  }

  const payload = {
    source: 'mac-bridge-yunxiao',
    received_at: new Date().toISOString(),
    headers: {
      'content-type': req.headers['content-type'] || '',
      'user-agent': req.headers['user-agent'] || '',
      'x-codeup-event': req.headers['x-codeup-event'] || req.headers['x-gitlab-event'] || '',
    },
    body: parsed,
  };

  const result = await forwardWebhook(yx.quality_webhook, payload, {
    label: 'quality-webhook',
  });

  ok(res, {
    ok: true,
    forwarded: !!(result && result.ok),
    downstream_status: result?.status ?? null,
  });
});

server.listen(port, host, () => {
  console.log(
    `mac-bridge yunxiao listening http://${host}:${port}${routePath} config=${cfg.__config_path}`,
  );
  console.log('healthz: GET /healthz');
  console.log('NOTE: do not change Codeup remote until tunnel + forward smoke pass');
});
