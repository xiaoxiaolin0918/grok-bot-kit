import { readTextFile } from './config.mjs';

/**
 * POST JSON to a Grok Bot webhook routine.
 * url/auth come from local files pointed by config (never committed).
 */
export async function forwardWebhook(target, payload, { label = 'forward' } = {}) {
  if (!target || !target.url_file) {
    console.error(label, 'skipped: no url_file in config');
    return { ok: false, skipped: true };
  }
  const url = readTextFile(target.url_file);
  if (!url) {
    console.error(label, 'skipped: empty url file', target.url_file);
    return { ok: false, skipped: true };
  }
  const headers = { 'content-type': 'application/json' };
  if (target.auth_file) {
    const auth = readTextFile(target.auth_file);
    if (auth) headers['authorization'] = auth;
  }
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(payload),
    });
    const text = await res.text();
    console.log(label, res.status, text.slice(0, 160));
    return { ok: res.ok, status: res.status, body: text.slice(0, 500) };
  } catch (e) {
    console.error(label, 'post failed', e.message);
    return { ok: false, error: e.message };
  }
}
