#!/usr/bin/env bash
set -euo pipefail
LAUNCH_DIR="${HOME}/Library/LaunchAgents"
uid="$(id -u)"
for name in com.example.grok-bridge.feishu com.example.grok-bridge.yunxiao com.example.grok-bridge.frpc; do
  launchctl bootout "gui/${uid}/${name}" 2>/dev/null || true
  rm -f "$LAUNCH_DIR/${name}.plist"
  echo "removed $name"
done
