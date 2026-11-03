# 03 · 引导式初始化

按步骤做。每步：**你将完成什么 → 怎么做 → 如何验收**。  
密钥只落在 **bridge host** 本机配置目录，勿贴进聊天或 git。

---

## 步骤 0 · 准备

**完成什么**  
确认账号、主机、占位符清单。

**怎么做**

1. 准备 Cursor / Grok Bot 账号（将只人工建管家）。
2. 选定一台 **常开主机**（**Linux / macOS / Windows**），下文称 bridge host；记下将对外暴露的 `<MAC_BRIDGE_HOST>`。
3. 克隆本 kit 到 bridge host（或任意可编辑机，再同步到 bridge host）：
   ```bash
   git clone <本仓 URL> zhiyi-bot-kit
   cd zhiyi-bot-kit
   ./scripts/init-guided.sh
   ```
4. 列出占位：`<ORG>`、`<MAC_BRIDGE_HOST>`、`<FEISHU_ASSISTANT_WEBHOOK>`、`<QUALITY_WEBHOOK>`、可选 `<MACHINE_ID>`。

**验收**  
`./scripts/init-guided.sh` 报告目录齐全；占位清单已写在笔记（勿含真实密钥）。

---

## 步骤 1 · 只建管家

**完成什么**  
侧栏出现「bot管家」，并读懂 steward 模板。

**怎么做**

1. 复制 `roles/steward/*.template.md` → 你的交接工作目录（如 `~/bot-roles/steward/`），去掉 `.template`，填占位。
2. CreateAgent：名称 bot管家；description / 系统提示取自 AGENT 浓缩职责。
3. 私聊管家：读该目录 AGENT+HANDOFF 升格；对照表角色见本 README（**无打印**）。

**验收**  
管家能复述：巡检时间 09:06/21:06、只建管家其余 CreateAgent、本 kit 不含打印。

---

## 步骤 2 · 管家拉起其余角色

**完成什么**  
侧栏有：飞书助手、智衣质量监管、代码审查；（可选）zhiyi cli。

**怎么做**

1. 为每个角色复制对应 `roles/<name>/*.template.md` 并填写。
2. 令管家按顺序 CreateAgent + 开工消息：
   - 飞书助手 → 质量监管 → 代码审查 →（可选）zhiyi cli
3. **不建**临时评审甲/乙/丙、群聊包、打印相关，除非负责人点名。

**验收**  
侧栏四（或五）个正式名齐全；各 bot 回复「已读 AGENT/HANDOFF」。

---

## 步骤 3 · 建巡检例程

**完成什么**  
「复活包早晚巡检」在跑。

**怎么做**  
管家创建例程：每天 **09:06** 与 **21:06**（Asia/Shanghai，含周末）；逻辑见 `docs/01-lines.md` §1。例程 **不随账号自动迁移**，换号必须重建。

**验收**  
例程列表可见同名两项时间；手动触发一次无报错（全齐可沉默）。

---

## 步骤 4 · 在 bridge host 安装收口桥

**完成什么**  
飞书 WS 与云效 HTTP 进程受守护运行。

**怎么做**

1. 在 bridge host：
   ```bash
   cd /path/to/zhiyi-bot-kit/mac-bridge
   npm install --omit=dev
   mkdir -p ~/.config/mac-bridge/{data,logs}
   cp config.example.json ~/.config/mac-bridge/config.json
   # 编辑 config.json；写入各 *_file 指向的密钥文件（见 05-security）
   ```
2. **进程守护（三选一，按 OS）**
   - Linux：`./scripts/install-systemd.sh`
   - macOS：`./scripts/install-launchd.sh`
   - Windows：见 `mac-bridge/scripts/windows/`（**NSSM** 或 **任务计划程序** PowerShell 示例）；先装 Node ≥18
3. 前台调试（可选）：`npm run feishu` / `npm run yunxiao`（三端相同）

**验收**

- `curl -sS http://127.0.0.1:8787/healthz` → 200
- 飞书进程日志无持续报错；私聊 bot 一句后飞书助手例程有 run（需步骤 5 填好转发）

---

## 步骤 5 · 挂接飞书助手 webhook

**完成什么**  
飞书消息直达「飞书助手」，不经管家代答。

**怎么做**

1. 在飞书助手侧建/确认唤醒例程，复制 URL 与 Authorization。
2. 写入 bridge host：
   ```bash
   printf '%s' '<FEISHU_ASSISTANT_WEBHOOK>' > ~/.config/mac-bridge/steward_webhook_url
   printf '%s' 'Bearer <TOKEN>' > ~/.config/mac-bridge/steward_webhook_auth
   chmod 600 ~/.config/mac-bridge/steward_webhook_* 
   ```
3. 飞书开放平台：长连接 / 事件订阅指向本应用；`app_id`、`app_secret`、`bot_open_id` 已写入主机文件。
4. 若曾有「管家飞书长连接唤醒」例程，**暂停**，避免双消费。

**验收**  
私聊一句 → OnIt（若开启）+ 飞书助手例程 run；群聊未 @ 不唤醒。

---

## 步骤 6 · 挂接质量监管 webhook + 公网

**完成什么**  
本机 smoke 能转到质量例程；公网 URL 已知但尚未改 Codeup。

**怎么做**

1. 质量监管建「Codeup CR Webhook」类例程 → 写入 `quality_webhook_url` / `quality_webhook_auth`。
2. 生成与 Codeup 将要填写的相同 Secret → `yunxiao_ingress_secret`。
3. 配置公网：frp example / cloudflared / 反代 → `<MAC_BRIDGE_HOST>/yunxiao/codeup`。
4. 跑 `./scripts/smoke-test.sh`（本机）；再用公网 URL 带 `X-Codeup-Token` 烟测。

**验收**  
本机与公网 POST 均 200；质量例程出现 smoke 唤醒；**此时仍不改 Codeup 远端**。

---

## 步骤 7 · 改 Codeup 远端（最后一步）

**完成什么**  
组织/仓 Webhook 指向桥公网地址。

**怎么做**

1. Codeup Webhook URL：`https://<MAC_BRIDGE_HOST>/yunxiao/codeup`
2. Secret Token = 主机 `yunxiao_ingress_secret` 全文（桥认 **`X-Codeup-Token`**）
3. 事件：至少 Merge Request Hook（按你们站规勾选）
4. 点「测试」；看 bridge 访问日志与质量例程。

**验收**  
测试与真实合入均 200；质量侧能解析到真实仓·CR·tip（非仅 iid=0 烟测）。

---

## 步骤 8 · 换号演练（可选但建议）

**完成什么**  
验证「只改转发文件」即可切账号。

**怎么做**  
在新账号重建管家与例程后，只更新主机上飞书助手 / 质量两对 url+auth 文件；重启或 kick 守护进程；再 smoke。

**验收**  
旧号例程不再被打到；新号例程有 run；飞书 app 无需重造（除非换应用）。
