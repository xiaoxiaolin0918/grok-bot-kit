# 02 · 架构与数据流（常开主机双入口）

## 总览

```
                    ┌──────────────────────────────────────┐
                    │  常开主机 bridge host（Linux/macOS/Windows） │
                    │                                      │
 飞书开放平台 ─WS──►│  mac-bridge feishu WS                 │──POST──► 飞书助手例程
                    │                                      │
 Codeup ─HTTPS────►│  公网隧道/反代 → yunxiao :8787        │──POST──► 质量监管例程
                    │     (~/.config/mac-bridge 或等价)       │
                    └──────────────────────────────────────┘
                                      │
                                      ▼
                         管家例程：巡检桥在线 + 角色包
```

**原则**：外网事件先落到 **bridge host**，再转发到**当前账号**的 Grok Bot webhook。换号时优先改两处转发文件，而不是重配飞书应用。  
**不要求**特定 Mac，也**不限于 Unix**：任选一台能常开、能出公网（或经隧道）的 **Linux / macOS / Windows** 主机即可。目录名 `mac-bridge` 为历史命名，语义=收口桥。

## 组件

| 组件 | 职责 |
|------|------|
| `mac-bridge/feishu` | 飞书 WS；过滤群 @；OnIt；转发飞书助手 |
| `mac-bridge/yunxiao` | Codeup HTTP 收口；Secret 校验；转发质量监管 |
| 主机配置目录（默认 `~/.config/mac-bridge/`） | **唯一**密钥与 webhook 落点（勿进 git） |
| 进程守护 | **Linux → systemd**；**macOS → launchd**；**Windows → NSSM 或任务计划程序** |
| bot管家 | CreateAgent、巡检、桥健康旁视 |
| 飞书助手 | 答飞书问题、代回 |
| 质量监管 | CR 调度、Approve/merge 站规 |
| 代码审查 | 主审 C/I/M + 可合档 |

## 配置文件关系

```
zhiyi-bot-kit/mac-bridge/config.example.json
        │ cp
        ▼
~/.config/mac-bridge/config.json          ← 只含路径指针与 app_id 占位
~/.config/mac-bridge/feishu_app_secret
~/.config/mac-bridge/bot_open_id
~/.config/mac-bridge/steward_webhook_url     ≈ <FEISHU_ASSISTANT_WEBHOOK>
~/.config/mac-bridge/steward_webhook_auth    ≈ Bearer …
~/.config/mac-bridge/quality_webhook_url     ≈ <QUALITY_WEBHOOK>
~/.config/mac-bridge/quality_webhook_auth
~/.config/mac-bridge/yunxiao_ingress_secret  ≈ Codeup Secret Token
~/.config/mac-bridge/frpc.toml               ← 可选公网
```

历史键名 `steward_webhook_*` 语义已是「飞书助手」；新部署可并列 `feishu_bot_webhook_*`（实现优先新键、回落旧键时以你采用的脚本为准）。

## 数据流细节

### 飞书入站

1. `im.message.receive_v1`
2. 写入主机 inbox.jsonl（可选）
3. 若应唤醒：并行 OnIt + POST webhook（不等 Cursor 响应体，避免堵 WS）
4. 飞书助手例程跑起来后自行拉上下文并回复飞书

### Codeup 入站

1. POST `/yunxiao/codeup`
2. 比对 Secret（**优先认 `X-Codeup-Token`**）
3. 包装 `source=mac-bridge-yunxiao` 后转发质量 webhook
4. 对 Codeup 回 200（本地已接受）

## machineId（可选）

仅当某角色需要 Cursor **本机** Shell/Read 时，在该角色 HANDOFF 填写 `<MACHINE_ID>`（以当前账号「已连接电脑」为准）。  
纯 webhook / 云端协作、或不碰本机文件系统的角色 **可留空**。bridge host 本身也不强制绑定 machineId。
