# mac-bridge — 收口桥骨架（kit 视角）

目录名 `mac-bridge` 为历史命名。语义是 **bridge host 上的双入口收口**：

1. **飞书**：常驻 WS 长连接 → 直达侧栏「飞书助手」webhook（不再经管家代答）
2. **云效/Codeup**：本机 HTTP 收口 → 直转「智衣质量监管」webhook；管家只巡检是否在线

**可跑在 Linux 或 macOS 常开主机**，不要求特定 Mac。密钥只落主机 `~/.config/mac-bridge/`，禁止进仓。

## 架构

```
飞书开放平台 ──WS──► feishu/ws-long-connection.mjs
                         └─POST─► <FEISHU_ASSISTANT_WEBHOOK>

Codeup ──HTTPS(<MAC_BRIDGE_HOST>)──► yunxiao/http-ingress.mjs
                         └─POST─► <QUALITY_WEBHOOK>
```

## 进程守护（二选一）

| 主机 | 安装 | 卸载 |
|------|------|------|
| macOS | `./scripts/install-launchd.sh` | `./scripts/uninstall-launchd.sh` |
| Linux | `./scripts/install-systemd.sh` | `./scripts/uninstall-systemd.sh` |

plist / unit 内为 `__BRIDGE_ROOT__` 等占位，安装脚本会替换为实际路径与 `node` 位置（可用 `NODE_BIN` / `FRPC_BIN` 覆盖）。

## 目录

| 路径 | 说明 |
|------|------|
| `config.example.json` | 配置样例 |
| `feishu/` / `yunxiao/` / `lib/` | 入口与转发 |
| `launchd/` | macOS 模板 |
| `systemd/` | Linux user unit 模板 |
| `scripts/smoke-test.sh` | 本机连通自测（默认带 `X-Codeup-Token`） |
| `frp/frpc.example.toml` | 可选公网 |

## 本机配置

```bash
mkdir -p ~/.config/mac-bridge/{data,logs}
cp config.example.json ~/.config/mac-bridge/config.json
# 编辑 app_id 与各 *_file

printf '%s' '飞书 app_secret' > ~/.config/mac-bridge/feishu_app_secret
printf '%s' 'ou_xxxx' > ~/.config/mac-bridge/bot_open_id
printf '%s' '<FEISHU_ASSISTANT_WEBHOOK>' > ~/.config/mac-bridge/steward_webhook_url
printf '%s' 'Bearer …' > ~/.config/mac-bridge/steward_webhook_auth
printf '%s' '<QUALITY_WEBHOOK>' > ~/.config/mac-bridge/quality_webhook_url
printf '%s' 'Bearer …' > ~/.config/mac-bridge/quality_webhook_auth
printf '%s' '与 Codeup Secret Token 相同的随机串' > ~/.config/mac-bridge/yunxiao_ingress_secret
chmod 600 ~/.config/mac-bridge/*secret* ~/.config/mac-bridge/*auth* ~/.config/mac-bridge/*url 2>/dev/null || true
```

## 安装

```bash
cd /path/to/zhiyi-bot-kit/mac-bridge
npm install --omit=dev
# macOS:
./scripts/install-launchd.sh
# Linux:
./scripts/install-systemd.sh
```

前台调试：`npm run feishu` / `npm run yunxiao`

## 公网

yunxiao 默认 `127.0.0.1:8787`。任选 frp（见 `frp/`）、cloudflared、ngrok 或反代到 `/yunxiao/codeup`。

**重要**：公网通 + `scripts/smoke-test.sh` 成功 + 质量例程有 run 之后，**再**改 Codeup 远端。Secret 头为 **`X-Codeup-Token`**。

## Codeup 改挂清单

1. URL：`https://<MAC_BRIDGE_HOST>/yunxiao/codeup`
2. Secret Token = `yunxiao_ingress_secret`
3. 点测试；看主机日志与质量例程
4. 换号通常只改飞书助手 / quality 转发文件

## 不做

- 不把密钥写进 commit
- 不在文档里要求必须使用某台 Mac mini
- 不捆绑打印开发材料
