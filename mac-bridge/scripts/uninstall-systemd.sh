#!/usr/bin/env bash
set -euo pipefail
UNIT_DIR="${HOME}/.config/systemd/user"
for u in mac-bridge-feishu mac-bridge-yunxiao mac-bridge-frpc; do
  systemctl --user disable --now "${u}.service" 2>/dev/null || true
  rm -f "$UNIT_DIR/${u}.service"
  echo "removed $u"
done
systemctl --user daemon-reload || true
