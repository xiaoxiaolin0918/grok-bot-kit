#!/usr/bin/env bash
set -euo pipefail
LAUNCH_DIR="${HOME}/Library/LaunchAgents"
uid="$(id -u)"
for name in com.zhiyi.mac-bridge.feishu com.zhiyi.mac-bridge.yunxiao com.zhiyi.mac-bridge.frpc; do
  launchctl bootout "gui/${uid}/${name}" 2>/dev/null || true
  rm -f "$LAUNCH_DIR/${name}.plist"
  echo "removed $name"
done
