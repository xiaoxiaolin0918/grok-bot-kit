#!/usr/bin/env bash
set -euo pipefail
BRIDGE="$(cd "$(dirname "$0")/.." && pwd)"
CFG_DIR="${HOME}/.config/mac-bridge"
LAUNCH_DIR="${HOME}/Library/LaunchAgents"
FRPC="${FRPC_BIN:-${HOME}/.local/bin/frpc}"
TOML="${CFG_DIR}/frpc.toml"
name=com.example.grok-bridge.frpc
mkdir -p "$CFG_DIR/logs" "$LAUNCH_DIR"
if [[ ! -x "$FRPC" ]]; then echo "缺少 $FRPC"; exit 1; fi
if [[ ! -f "$TOML" ]]; then echo "缺少 $TOML；cp $BRIDGE/frp/frpc.example.toml $TOML"; exit 1; fi
if grep -qE 'YOUR_FRPS_HOST|YOUR_FRPS_TOKEN' "$TOML"; then
  echo "配置仍是占位符 YOUR_FRPS_*"; exit 2
fi
uid="$(id -u)"
dst="$LAUNCH_DIR/${name}.plist"
sed -e "s|__BRIDGE_ROOT__|${BRIDGE}|g" \
    -e "s|__HOME__|${HOME}|g" \
    -e "s|__PATH_EXTRA__|$(dirname "$FRPC"):|g" \
    -e "s|__FRPC_BIN__|${FRPC}|g" \
    -e "s|__NODE_BIN__|placeholder|g" \
    "$BRIDGE/launchd/${name}.plist" > "$dst"
launchctl bootout "gui/${uid}/${name}" 2>/dev/null || true
launchctl bootstrap "gui/${uid}" "$dst"
launchctl enable "gui/${uid}/${name}" 2>/dev/null || true
launchctl kickstart -k "gui/${uid}/${name}" 2>/dev/null || true
echo "loaded $name"
