# mac-bridge — 收口桥骨架（kit 视角）

目录名 `mac-bridge` 为历史命名。语义是 **bridge host 上的双入口收口**：

1. **飞书**：常驻 WS 长连接 → 直达侧栏「飞书答疑」webhook（不再经管家代答）
2. **云效/Codeup**：本机 HTTP 收口 → 直转「质量调度」webhook；管家只巡检是否在线

**可跑在 Linux / macOS / Windows 常开主机**，不要求特定机型，**不是仅 Unix**。  
运行时用 **Node ≥18** 执行同一套 `feishu` / `yunxiao` 脚本。密钥只落主机配置目录（默认 `~/.config/mac-bridge/` 或 Windows `%USERPROFILE%\.config\mac-bridge\`），禁止进仓。

## 架构

```
飞书开放平台 ──WS──► feishu/ws-long-connection.mjs
                         └─POST─► <FEISHU_ASSISTANT_WEBHOOK>

Codeup ──HTTPS(<BRIDGE_HOST>)──► yunxiao/http-ingress.mjs
                         └─POST─► <QUALITY_WEBHOOK>
```

## 进程守护（三端）

| 主机 OS | 安装 | 卸载 / 说明 |
|---------|------|-------------|
| Linux | `./scripts/install-systemd.sh` | `./scripts/uninstall-systemd.sh`；`Restart=always` |
| macOS | `./scripts/install-launchd.sh` | `./scripts/uninstall-launchd.sh`；KeepAlive |
| Windows | `scripts/windows/` 下 **NSSM** 或 **任务计划程序** 示例 | 见该目录 README；服务失败自动重启 |

plist / unit 内为 `__BRIDGE_ROOT__` 等占位，Unix 安装脚本会替换路径与 `node`（可用 `NODE_BIN` / `FRPC_BIN`）。Windows 请在示例脚本里改 `$BridgeRoot` / `$NodeBin`。

## 目录

| 路径 | 说明 |
|------|------|
| `config.example.json` | 配置样例 |
| `feishu/` / `yunxiao/` / `lib/` | 入口与转发（跨平台 Node） |
| `launchd/` | macOS 模板 |
| `systemd/` | Linux user unit 模板 |
| `scripts/windows/` | Windows：NSSM / 任务计划程序 |
| `scripts/smoke-test.sh` | 本机连通自测（Git Bash/WSL/macOS/Linux；默认 `X-Codeup-Token`） |
| `frp/frpc.example.toml` | 可选公网（三端均可跑 frpc） |

## 本机配置

```bash
# Linux / macOS / Git Bash / WSL
mkdir -p ~/.config/mac-bridge/data ~/.config/mac-bridge/logs
cp config.example.json ~/.config/mac-bridge/config.json
```

Windows PowerShell 等价：

```powershell
$Cfg = Join-Path $env:USERPROFILE '.config\mac-bridge'
New-Item -ItemType Directory -Force -Path "$Cfg\data","$Cfg\logs" | Out-Null
Copy-Item .\config.example.json "$Cfg\config.json"
# 编辑 config.json；密钥写成无换行的文本文件（见下）
```

```bash
printf '%s' '飞书 app_secret' > ~/.config/mac-bridge/feishu_app_secret
printf '%s' 'ou_xxxx' > ~/.config/mac-bridge/bot_open_id
printf '%s' '<FEISHU_ASSISTANT_WEBHOOK>' > ~/.config/mac-bridge/steward_webhook_url
printf '%s' 'Bearer …' > ~/.config/mac-bridge/steward_webhook_auth
printf '%s' '<QUALITY_WEBHOOK>' > ~/.config/mac-bridge/quality_webhook_url
printf '%s' 'Bearer …' > ~/.config/mac-bridge/quality_webhook_auth
printf '%s' '与 Codeup Secret Token 相同的随机串' > ~/.config/mac-bridge/yunxiao_ingress_secret
chmod 600 ~/.config/mac-bridge/*secret* ~/.config/mac-bridge/*auth* ~/.config/mac-bridge/*url 2>/dev/null || true
```

也可用环境变量 `MAC_BRIDGE_CONFIG` 指向任意 `config.json`。

## 安装依赖与前台调试（三端相同）

```bash
cd /path/to/grok-bot-kit/mac-bridge
npm install --omit=dev
npm run feishu    # WS
npm run yunxiao   # HTTP 127.0.0.1:8787
```

确认前台正常后，再挂进程守护（上表）。

## 公网

yunxiao 默认只听 `127.0.0.1:8787`。任选：

- frp（见 `frp/`；Windows 同样可跑 `frpc.exe`）
- cloudflared / ngrok
- 已有反向代理 → `/yunxiao/codeup`

**重要**：公网通 + smoke 成功 + 质量例程有 run 之后，**再**改 Codeup 远端。Secret 头为 **`X-Codeup-Token`**。

## Codeup 改挂清单

1. URL：`https://<BRIDGE_HOST>/yunxiao/codeup`
2. Secret Token = `yunxiao_ingress_secret`
3. 点测试；看主机日志与质量例程
4. 换号通常只改飞书答疑 / quality 转发文件

## 不做

- 不把密钥写进 commit
- 不暗示必须 Mac mini 或仅 Unix
- 不捆绑打印开发材料
