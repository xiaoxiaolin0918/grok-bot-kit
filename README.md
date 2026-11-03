# zhiyi-bot-kit

给同事迁移 / 初始化用的 **脱敏工具包**：说明 Grok Bot 日常协作里几条正式流程线的作用与实现，并提供引导式搭建步骤与角色模板。

> **不是**完整复活仓镜像。不含个人巡检日志、不含真实密钥、**不含打印开发机器人**材料。

## 给谁

- 需要在新账号上搭齐「管家 + 飞书助手 + 质量监管 + 代码审查」（可选 zhiyi-cli）的同事
- 需要理解「常开主机」上双入口收口桥（飞书 WS / Codeup HTTP）的运维同学

## 本仓有什么

| 路径 | 内容 |
|------|------|
| `docs/` | 流程线、架构、引导式初始化、验收清单、安全约定 |
| `roles/` | 各角色 `AGENT.template.md` / `HANDOFF.template.md`（复制后按占位符填写） |
| `mac-bridge/` | 可安装的收口桥骨架（目录名沿用历史；**可跑在 Linux 或 macOS 常开主机**；仅 example 配置） |
| `scripts/init-guided.sh` | 打印引导步骤并检查本仓目录是否齐全（不索要密码） |

## 正式对照角色（本 kit）

| 角色模板目录 | 建议侧栏名 | 是否必装 |
|--------------|------------|----------|
| `roles/steward` | bot管家 | 必装（人工只建这一个） |
| `roles/feishu-assistant` | 飞书助手 | 必装（飞书问答） |
| `roles/quality` | 智衣质量监管 | 必装（Codeup/CR 调度） |
| `roles/code-review` | 代码审查 | 必装（主审） |
| `roles/zhiyi-cli` | zhiyi cli | 可选（后端 CLI 开发） |

**打印开发机器人不在本 kit。** 若业务需要打印线，请另册，勿并入本仓对照表。

## 最快开始

1. 读 [`docs/01-lines.md`](docs/01-lines.md) 与 [`docs/02-architecture.md`](docs/02-architecture.md)
2. 按 [`docs/03-guided-setup.md`](docs/03-guided-setup.md) 逐步做；每步有「完成什么 / 怎么做 / 如何验收」
3. 用 [`docs/04-checklist.md`](docs/04-checklist.md) 勾验收
4. 密钥落点见 [`docs/05-security.md`](docs/05-security.md)

也可跑：

```bash
./scripts/init-guided.sh
```

## 复活约定（摘要）

1. **人工只建管家**；其余由管家 `CreateAgent` 拉起并发送开工消息
2. 巡检例程：每天 **09:06** / **21:06**（Asia/Shanghai，含周末）；缺漏/过旧才催，全齐沉默
3. **收口桥**跑在一台 **常开主机（bridge host）** 上即可（Linux / macOS 均可），**不要求**必须是某台特定 Mac
4. **进程守护**：macOS 用 launchd，Linux 用 systemd（二选一）；见 `mac-bridge/README.md`
5. **Codeup**：桥 + 公网可达 + smoke 通过后，再改远端 Webhook；Secret 头为 **`X-Codeup-Token`**（桥同时兼容 `X-Mac-Bridge-Secret` / `X-Gitlab-Token` / `?secret=`）
6. 换号：通常只改主机上转发文件（飞书助手 / 质量监管的 webhook URL+Authorization），飞书 app 凭证可留主机
7. 侧栏 agent id、Cursor `machineId` **以当前账号侧栏 / 已连接电脑为准**；模板只用占位。`machineId` **可选**——仅当该角色需要 Cursor 本机 Shell/Read 时再填

## 建议远端（待负责人确认）

空仓名建议：`sanzhi/private/zhiyi-bot-kit`（Codeup）。本仓首次 commit **默认不 push**，等确认远端后再挂。

## 不做

- 不暴露完整复活仓内容与历史
- 不提交任何真实 Bearer / app_secret / ingress secret / frp token / 真实 webhook URL
- 不把本 kit 当业务仓使用
- 不暗示桥必须跑在 Mac mini 上
