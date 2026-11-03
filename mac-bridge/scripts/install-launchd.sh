#!/usr/bin/env bash
# macOS：安装 / 重装收口桥 launchd（KeepAlive）
set -euo pipefail
BRIDGE="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="${HOME}/.config/mac-bridge"
LAUNCH_DIR="${HOME}/Library/LaunchAgents"
NODE_BIN="${NODE_BIN:-$(command -v node || true)}"
PATH_EXTRA="$(dirname "${NODE_BIN:-/usr/bin}")":
mkdir -p "$CFG_DIR/logs" "$CFG_DIR/data" "$LAUNCH_DIR"

if [[ -z "$NODE_BIN" ]]; then
  echo "找不到 node；请安装 Node >=18 或 export NODE_BIN=/path/to/node"
  exit 1
fi
if [[ ! -f "$CFG_DIR/config.json" ]]; then
  echo "缺少 $CFG_DIR/config.json"
  echo "先: cp $BRIDGE/config.example.json $CFG_DIR/config.json 并填写"
  exit 1
fi
if [[ ! -d "$BRIDGE/node_modules/@larksuiteoapi/node-sdk" ]]; then
  echo "安装 npm 依赖…"
  (cd "$BRIDGE" && npm install --omit=dev)
fi

uid="$(id -u)"
render() {
  local src="$1" dst="$2"
  sed -e "s|__BRIDGE_ROOT__|${BRIDGE}|g" \
      -e "s|__NODE_BIN__|${NODE_BIN}|g" \
      -e "s|__HOME__|${HOME}|g" \
      -e "s|__PATH_EXTRA__|${PATH_EXTRA}|g" \
      -e "s|__FRPC_BIN__|${FRPC_BIN:-${HOME}/.local/bin/frpc}|g" \
      "$src" > "$dst"
}

for name in com.zhiyi.mac-bridge.feishu com.zhiyi.mac-bridge.yunxiao; do
  src="$BRIDGE/launchd/${name}.plist"
  dst="$LAUNCH_DIR/${name}.plist"
  render "$src" "$dst"
  launchctl bootout "gui/${uid}/${name}" 2>/dev/null || true
  launchctl bootstrap "gui/${uid}" "$dst"
  launchctl enable "gui/${uid}/${name}" 2>/dev/null || true
  launchctl kickstart -k "gui/${uid}/${name}" 2>/dev/null || true
  echo "loaded $name"
done

echo "日志: $CFG_DIR/logs/"
echo "状态: launchctl print gui/${uid}/com.zhiyi.mac-bridge.feishu | head"
if [[ -x "${FRPC_BIN:-$HOME/.local/bin/frpc}" && -f "$CFG_DIR/frpc.toml" ]] && ! grep -qE 'YOUR_FRPS_HOST|YOUR_FRPS_TOKEN' "$CFG_DIR/frpc.toml" 2>/dev/null; then
  "$BRIDGE/scripts/install-frpc-launchd.sh" || true
else
  echo "跳过 frpc：填写 $CFG_DIR/frpc.toml 后执行 ./scripts/install-frpc-launchd.sh"
fi
