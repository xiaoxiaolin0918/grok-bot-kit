#!/usr/bin/env bash
# 打印引导步骤并检查本仓目录是否齐全（不交互、不索要密码）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== zhiyi-bot-kit 引导检查 ==="
echo "根目录: $ROOT"
echo

need=(
  README.md
  docs/01-lines.md
  docs/02-architecture.md
  docs/03-guided-setup.md
  docs/04-checklist.md
  docs/05-security.md
  roles/steward/AGENT.template.md
  roles/steward/HANDOFF.template.md
  roles/feishu-assistant/AGENT.template.md
  roles/feishu-assistant/HANDOFF.template.md
  roles/quality/AGENT.template.md
  roles/quality/HANDOFF.template.md
  roles/code-review/AGENT.template.md
  roles/code-review/HANDOFF.template.md
  roles/zhiyi-cli/AGENT.template.md
  roles/zhiyi-cli/HANDOFF.template.md
  mac-bridge/README.md
  mac-bridge/config.example.json
  mac-bridge/feishu/ws-long-connection.mjs
  mac-bridge/yunxiao/http-ingress.mjs
  mac-bridge/lib/config.mjs
  mac-bridge/lib/forward.mjs
  mac-bridge/scripts/smoke-test.sh
  mac-bridge/scripts/install-launchd.sh
  mac-bridge/scripts/install-systemd.sh
  mac-bridge/frp/frpc.example.toml
)

miss=0
for f in "${need[@]}"; do
  if [[ -e "$f" ]]; then
    echo "OK   $f"
  else
    echo "MISS $f"
    miss=$((miss+1))
  fi
done

echo
if [[ $miss -gt 0 ]]; then
  echo "缺失 $miss 项；请勿继续对外分发。"
  exit 1
fi

# 粗检：不应出现打印包目录
if [[ -d roles/zhiyi-print || -d zhiyi-print ]]; then
  echo "警告：发现打印相关目录，本 kit 应排除打印。"
  exit 2
fi

echo "目录齐全。"
echo
echo "下一步（详见 docs/03-guided-setup.md）："
echo "  0) 选定常开 bridge host（Linux/macOS）与占位符"
echo "  1) 只建管家（roles/steward）"
echo "  2) 管家 CreateAgent：飞书助手 → 质量 → 代码审查 →（可选）zhiyi-cli"
echo "  3) 巡检例程 09:06 / 21:06 Asia/Shanghai"
echo "  4) 在 bridge host 安装 mac-bridge（launchd 或 systemd）"
echo "  5) 挂飞书助手 webhook"
echo "  6) 挂质量 webhook + 公网 smoke（头 X-Codeup-Token）"
echo "  7) 最后才改 Codeup 远端"
echo "  8) （可选）换号只改转发文件"
echo
echo "本脚本不读取、不索要任何密钥。"
