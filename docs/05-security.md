# 05 · 安全约定

## 密钥落点（唯一）

| 内容 | 落点 | 进 git？ |
|------|------|----------|
| 飞书 app_secret | bridge host `~/.config/mac-bridge/feishu_app_secret` | ❌ |
| bot open_id | 同上 `bot_open_id` | ❌（非高密但勿散播） |
| 飞书答疑 webhook URL/Auth | `steward_webhook_url` / `steward_webhook_auth`（或 `feishu_bot_webhook_*`） | ❌ |
| 质量调度 webhook URL/Auth | `quality_webhook_*` | ❌ |
| Codeup / 桥共享 Secret | `yunxiao_ingress_secret` | ❌ |
| frp token / 域名真实值 | `frpc.toml`（由 example 复制） | ❌ |
| Cursor machineId | 角色 HANDOFF 可选字段 | 可写 id 本身；**勿**当跨账号唯一真相 |

应用配置 `config.json` 只保留 **路径指针** 与非机密开关；真正密钥一律外置文件。

## 禁止进仓

- 任何 Bearer、token、password、AccessKey、私钥
- 真实 `<FEISHU_ASSISTANT_WEBHOOK>` / `<QUALITY_WEBHOOK>` 全文
- 冗长个人巡检日志、夜巡流水
- 打印开发机器人业务材料
- 把某人的 agent id 写成「全局唯一不可变」

## Codeup Secret 头

Codeup 后台填写的 Secret Token，请求里是：

```http
X-Codeup-Token: <与 yunxiao_ingress_secret 相同>
```

桥实现同时兼容：`X-Mac-Bridge-Secret`、`X-Gitlab-Token`、`?secret=`。烟测与现网应用同一值。

## 换号只改转发文件

通常足够：

1. `steward_webhook_url` + `steward_webhook_auth` → 新账号飞书答疑例程  
2. `quality_webhook_url` + `quality_webhook_auth` → 新账号质量例程  
3. 重建管家与巡检例程（例程不随账号迁移）  
4. kick/restart 守护进程  

通常 **不必**：重造飞书企业自建应用、重装 Node 依赖、改 Codeup URL（若 `<BRIDGE_HOST>` 未变）。

若换了飞书应用或桥主机，再轮换 app_secret / ingress secret，并同步改 Codeup Secret。

## 日志

主机 `logs/` 可能含会话摘要。默认 gitignore。对外分享前先脱敏或删除。

Windows 上配置目录仍建议 `%USERPROFILE%\.config\mac-bridge\`（与示例一致），或通过环境变量 `MAC_BRIDGE_CONFIG` 指向任意路径。


## Public GitHub preflight

Before making the repository Public on GitHub:

1. Run `./scripts/public-scan.sh` and fix any FAIL.
2. Confirm no real secrets under `~/.config/mac-bridge/` were ever copied into the tree.
3. Confirm print / manufacturing bots are not present.
4. Suggested public name: `grok-bot-kit`. Do not push until the owner names the GitHub org/user.
