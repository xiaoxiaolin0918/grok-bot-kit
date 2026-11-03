# Grok Bot Kit (`grok-bot-kit`)

**English (short):** A sanitized, public-friendly toolkit for migrating and bootstrapping **Grok Bot** team workflows: steward + Feishu Q&A assistant + quality dispatcher + code review (+ optional dev CLI), plus an always-on **bridge host** (Linux / macOS / Windows) that receives Feishu WebSocket events and Git forge (Codeup/GitLab-compatible) webhooks. No secrets in git. MIT licensed. **Do not push** until you choose a public GitHub name.

**中文：** 给同事迁移 / 初始化用的 **Grok Bot 协作工具包**（脱敏、可公开）。说明几条正式流程线的作用与实现，并提供引导式搭建、角色模板与收口桥骨架。

> 不含个人巡检日志、不含真实密钥、**不含打印产线机器人**材料。不含公司真名、内网域名、真实 org/agent id。

## Who it’s for / 给谁

- 需要在新账号上搭齐「管家 + 飞书答疑 + 质量调度 + 代码审查」（可选 dev-cli）的同事
- 需要在 **常开主机**（Linux / macOS / **Windows**）上跑双入口收口桥的运维同学

## Layout

| Path | Content |
|------|---------|
| `docs/` | Lines, architecture, guided setup, checklist, security |
| `roles/` | `AGENT.template.md` / `HANDOFF.template.md` per role |
| `mac-bridge/` | Runnable bridge skeleton (example config only) |
| `scripts/init-guided.sh` | Print steps + verify tree (no passwords) |
| `scripts/public-scan.sh` | Pre-publish scan: secrets, private IPs, emails |
| `LICENSE` | MIT |

## Official roles in this kit

| Template dir | Suggested sidebar name | Required? |
|--------------|------------------------|-----------|
| `roles/steward` | bot管家 / Steward | Yes (human creates only this one) |
| `roles/feishu-assistant` | 飞书答疑 / Feishu assistant | Yes |
| `roles/quality` | 质量调度 / Quality | Yes (MR/CR dispatch) |
| `roles/code-review` | 代码审查 / Code review | Yes |
| `roles/dev-cli` | dev-cli | Optional |

**Print / manufacturing bots are out of scope** for this kit.

## Quick start

1. Read [`docs/01-lines.md`](docs/01-lines.md) and [`docs/02-architecture.md`](docs/02-architecture.md)
2. Follow [`docs/03-guided-setup.md`](docs/03-guided-setup.md)
3. Check [`docs/04-checklist.md`](docs/04-checklist.md) and [`docs/05-security.md`](docs/05-security.md)
4. Before any public push: `./scripts/public-scan.sh`

```bash
./scripts/init-guided.sh
./scripts/public-scan.sh
```

## Conventions (summary)

1. **Human creates only the steward**; steward `CreateAgent`s the rest
2. Patrol routine: **09:06** / **21:06** Asia/Shanghai (weekends included); silent when healthy
3. **Bridge host** = always-on Linux / macOS / Windows (not tied to one vendor laptop)
4. **Supervision:** Linux→systemd; macOS→launchd; Windows→**NSSM** or **Task Scheduler**
5. **Git forge webhooks:** smoke first, then point remote URL at `https://<BRIDGE_HOST>/yunxiao/codeup` (path configurable). Secret header for Codeup-compatible forges: **`X-Codeup-Token`**
6. Account switch: usually only rewrite local forwarder URL/auth files
7. Sidebar agent ids and Cursor `machineId` are **optional placeholders** — never treat copied ids as global truth

## Suggested public repo name

`grok-bot-kit` on GitHub (Public). **No remote configured; do not push until the owner names the org/user.**

## Placeholders

`<ORG>`, `<BRIDGE_HOST>`, `<FEISHU_ASSISTANT_WEBHOOK>`, `<QUALITY_WEBHOOK>`, `<USER_NAME>`, `<MACHINE_ID>` (optional), `example.com`

## Non-goals

- No real Bearer / app_secret / ingress secret / frp token / webhook URLs in git
- No company intranet hostnames, personal names, or internal agent ids
- Not a business application monorepo
