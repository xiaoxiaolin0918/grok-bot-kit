#!/usr/bin/env bash
# 本地连通自测（不改 Codeup 远端）
set -euo pipefail
export MAC_BRIDGE_CONFIG="${MAC_BRIDGE_CONFIG:-$HOME/.config/mac-bridge/config.json}"
PORT="$(python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ['MAC_BRIDGE_CONFIG'])
if not p.exists():
    print('8787'); raise SystemExit
cfg = json.loads(p.read_text())
print(cfg.get('yunxiao', {}).get('listen_port', 8787))
PY
)"
HOST="$(python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ['MAC_BRIDGE_CONFIG'])
if not p.exists():
    print('127.0.0.1'); raise SystemExit
cfg = json.loads(p.read_text())
print(cfg.get('yunxiao', {}).get('listen_host', '127.0.0.1'))
PY
)"
PATH_Y="$(python3 - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ['MAC_BRIDGE_CONFIG'])
if not p.exists():
    print('/yunxiao/codeup'); raise SystemExit
cfg = json.loads(p.read_text())
print(cfg.get('yunxiao', {}).get('path', '/yunxiao/codeup'))
PY
)"

echo "== healthz =="
curl -sS "http://${HOST}:${PORT}/healthz" || { echo "yunxiao 未起来；先 install-launchd / install-systemd 或 npm run yunxiao"; exit 1; }
echo
echo "== POST 假事件（可带 X-Codeup-Token） =="
SECRET_FILE="$HOME/.config/mac-bridge/yunxiao_ingress_secret"
HDR=()
if [[ -f "$SECRET_FILE" ]]; then
  SEC="$(tr -d '\n' < "$SECRET_FILE")"
  HDR=(-H "X-Codeup-Token: ${SEC}")
fi
curl -sS "${HDR[@]}" -H 'content-type: application/json' \
  -d '{"object_kind":"merge_request","smoke":true,"note":"mac-bridge local smoke"}' \
  "http://${HOST}:${PORT}${PATH_Y}"
echo
echo "== 飞书 =="
echo "对 bot 私聊一句 → 飞书答疑例程应 run；看 logs/feishu.*.log"
echo "== 配置检查（不打印密钥内容） =="
python3 - <<'PY'
from pathlib import Path
import os, json
cfg_path = Path(os.environ.get('MAC_BRIDGE_CONFIG', Path.home()/'.config/mac-bridge/config.json'))
print('config:', cfg_path, 'exists=', cfg_path.exists())
if not cfg_path.exists():
    raise SystemExit(0)
cfg = json.loads(cfg_path.read_text())
files = []
f = cfg.get('feishu', {})
files += [
  ('feishu.app_secret_file', f.get('app_secret_file')),
  ('feishu assistant url', (f.get('steward_webhook') or {}).get('url_file')),
  ('feishu assistant auth', (f.get('steward_webhook') or {}).get('auth_file')),
]
y = cfg.get('yunxiao', {})
files += [
  ('yunxiao secret', y.get('shared_secret_file')),
  ('quality url', (y.get('quality_webhook') or {}).get('url_file')),
  ('quality auth', (y.get('quality_webhook') or {}).get('auth_file')),
]
home = Path.home()
def exp(p):
    if not p: return None
    p = str(p)
    return Path(p.replace('~', str(home), 1)) if p.startswith('~') else Path(p)
for label, p in files:
    ep = exp(p)
    ok = bool(ep and ep.exists() and ep.stat().st_size > 0)
    print(f'  {label}: {"OK" if ok else "MISSING"} ({p})')
PY
