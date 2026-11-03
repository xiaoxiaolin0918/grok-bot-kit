# 01 · 各流程线：作用与实现逻辑

本 kit **不含打印线**。正式线如下。

占位约定：`<ORG>`、`<MAC_BRIDGE_HOST>`（常开主机对外域名或 IP）、`<FEISHU_ASSISTANT_WEBHOOK>`、`<QUALITY_WEBHOOK>`、`<MACHINE_ID>`（可选）。

---

## 1. 复活包巡检（管家）

**作用**  
保证各正式角色的交接材料（`AGENT.md` + `HANDOFF.md`）齐全、不过旧；换号后能按包续工。

**实现逻辑**

1. 人工在侧栏只建 **bot管家**，令其读 `roles/steward` 模板升格。
2. 管家按对照表 `CreateAgent` 拉起其余正式角色，并各发开工消息。
3. 建例程「复活包早晚巡检」：每天 **09:06** / **21:06**（Asia/Shanghai，含周末）。
4. 巡检：缺 `HANDOFF`/`AGENT`、过旧（>7 天）、空模板、疑似密钥（只记位置不贴值）→ 催对应 bot；**全齐则对用户沉默**。
5. 附加：若能连上 bridge host，抽查飞书/云效进程是否在跑、转发文件是否指向**本账号**例程（不读出密钥）。

**不做**：业务代码、发版、评审、写密钥；临时评审甲/乙/丙、群聊默认不进对照表。

---

## 2. 飞书实施答疑（飞书助手 + 收口桥）

**作用**  
飞书私聊 / 群聊 @bot 的实施与查数问题，由专用「飞书助手」回答；换号时不必重挂飞书开放平台应用。

**实现逻辑**

```
飞书开放平台 ──WS──► bridge-host: feishu/ws-long-connection.mjs
                         │  OnIt 表情占坑（可选）
                         └─POST─► <FEISHU_ASSISTANT_WEBHOOK>
                                   （主机 steward_webhook_* 或 feishu_bot_webhook_*）
```

1. 在 **常开主机**（Linux / macOS / Windows）上跑 WS 长连接；进程守护见下表。
2. **私聊一律唤醒**；**群聊仅真正 @bot**（按 bot open_id / 名称正则），未 @ 不唤醒。
3. 转发目标是「飞书助手」例程 webhook，**不再经管家代答**（管家只巡检桥是否在线）。
4. 可选：异步 ingest 到主机 FAQ sqlite（路径自配；本 kit 不捆绑完整 feishu-qa 仓）。
5. 代回：助手用飞书开放 API / 自备脚本引用回复；长排查可开话题。

**换号**：改主机转发 URL/Authorization 文件即可；`app_id` / `app_secret` 可保留。

### 进程守护（三端）

| 主机 OS | 守护方式 |
|---------|----------|
| Linux | systemd（user 或 system unit，`Restart=always`） |
| macOS | launchd KeepAlive |
| Windows | **NSSM** 将 `node …` 注册为服务，或**任务计划程序**（登录/启动时运行并失败重启） |

Node 进程本身跨平台：`npm run feishu` / `npm run yunxiao`。公网仍用 frp / cloudflared / ngrok / 反代转到本机 `8787`。

---

## 3. Codeup 合入 / CR（质量监管 + 代码审查 + 收口桥）

**作用**  
Codeup Merge Request / CR 事件自动进「质量监管」调度，再分派「代码审查」或临时审角；质量侧负责 Approve /（按站规）merge。

**实现逻辑**

```
Codeup ──HTTPS(<MAC_BRIDGE_HOST>)──► bridge-host: yunxiao/http-ingress.mjs
                                         │  校验 Secret（见下）
                                         └─POST─► <QUALITY_WEBHOOK>
```

1. 主机 HTTP 默认 `127.0.0.1:8787`，路径 `/yunxiao/codeup`。
2. 公网：frp / cloudflared / ngrok / 现有反代 → `<MAC_BRIDGE_HOST>/yunxiao/codeup`。
3. **Secret**：Codeup「Secret Token」发在请求头 **`X-Codeup-Token`**。桥同时接受 `X-Mac-Bridge-Secret`、`X-Gitlab-Token`、`?secret=`。
4. 校验通过后转质量监管 webhook；对 Codeup 本地接受后回 200，避免重试堆积。
5. 质量监管：解析仓/CR/tip → 分派主审 → 汇总结论 → **Approve 与能否 merge 分开**（站规写在质量/审查模板）。

**改远端时机（硬）**：公网可达 + `scripts/smoke-test.sh` 成功 + 质量例程能看到唤醒 → **再**改 Codeup Webhook。未就绪前勿改。

---

## 4. zhiyi-cli（可选开发主战场）

**作用**  
智衣后端 CLI（`zhiyi-cli`）任务驱动开发：查数、运维命令、补 CLI 缺口。

**实现逻辑（摘要）**

- 业务仓与「角色复活材料」分离：角色模板在本 kit / 你的私有交接目录；**不把交接材料 commit 进业务仓**。
- 推送走 Codeup 评审引用（如 `refs/for/master/<topic>`），日常勿直推 `master` tip。
- 原子命令 vs 集成流程分层；破坏性操作先确认。
- 若需 Cursor 本机工具，再填写可选 `<MACHINE_ID>`；纯云端对话可不填。

---

## 5. 辅助（非本 kit 交付物）

常另备：`yunxiao` CLI（指定 profile）、日志查询 CLI 等。合入信息在桥故障时可用 API/CLI **扫仓兜底**，但不能替代正式 webhook 路径。

---

## 对照：本 kit vs 完整复活仓

| | 本 kit | 完整复活仓（不公开） |
|--|--------|---------------------|
| 打印开发 | ❌ 排除 | 可能有 |
| 真实密钥 / 个人 agent id | ❌ 占位 | 主机/本机私有 |
| 冗长巡检史 | ❌ | 有 |
| 收口桥可运行骨架 | ✅ example；Linux/macOS/Windows | 同思路 |
| 引导式初始化 | ✅ | 可能散落在 HANDOFF |
| 桥必须 Mac / 仅 Unix | ❌ 否 | 视部署而定 |
