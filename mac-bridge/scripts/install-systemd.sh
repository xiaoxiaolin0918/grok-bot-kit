#!/usr/bin/env bash
# Linux：安装 user systemd 单元（Restart=always）
set -euo pipefail
BRIDGE="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="${HOME}/.config/mac-bridge"
UNIT_DIR="${HOME}/.config/systemd/user"
NODE_BIN="${NODE_BIN:-$(command -v node || true)}"
FRPC_BIN="${FRPC_BIN:-$(command -v frpc || true)}"
FRPC_BIN="${FRPC_BIN:-$HOME/.local/bin/frpc}"
mkdir -p "$CFG_DIR/logs" "$CFG_DIR/data" "$UNIT_DIR"

if [[ -z "$NODE_BIN" ]]; then echo "找不到 node"; exit 1; fi
if [[ ! -f "$CFG_DIR/config.json" ]]; then
  echo "缺少 $CFG_DIR/config.json"; exit 1
fi
if [[ ! -d "$BRIDGE/node_modules/@larksuiteoapi/node-sdk" ]]; then
  (cd "$BRIDGE" && npm install --omit=dev)
fi

render() {
  sed -e "s|__BRIDGE_ROOT__|${BRIDGE}|g" \
      -e "s|__NODE_BIN__|${NODE_BIN}|g" \
      -e "s|__FRPC_BIN__|${FRPC_BIN}|g" \
      "$1" > "$2"
}

for u in mac-bridge-feishu mac-bridge-yunxiao; do
  render "$BRIDGE/systemd/${u}.service" "$UNIT_DIR/${u}.service"
done

systemctl --user daemon-reload
systemctl --user enable --now mac-bridge-feishu.service mac-bridge-yunxiao.service
echo "enabled user units; logs in $CFG_DIR/logs/"
echo "若注销后需继续跑: loginctl enable-linger \$USER"

if [[ -x "$FRPC_BIN" && -f "$CFG_DIR/frpc.toml" ]] && ! grep -qE 'YOUR_FRPS_HOST|YOUR_FRPS_TOKEN' "$CFG_DIR/frpc.toml"; then
  render "$BRIDGE/systemd/mac-bridge-frpc.service" "$UNIT_DIR/mac-bridge-frpc.service"
  systemctl --user daemon-reload
  systemctl --user enable --now mac-bridge-frpc.service
  echo "frpc enabled"
else
  echo "跳过 frpc unit"
fi
