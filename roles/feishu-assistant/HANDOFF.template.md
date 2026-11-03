# 飞书答疑 · HANDOFF 模板

## 入口

```
飞书 ──WS──► bridge host mac-bridge/feishu
                └─POST─► 本 bot 唤醒例程
```

主机转发文件（示例名）：`steward_webhook_url` / `steward_webhook_auth`（语义=飞书答疑）。

## 本机/主机线索

| 项 | 值 |
|----|-----|
| 开放平台 app_id | 见主机 config（勿抄 secret 到本文件） |
| 代回方式 | 飞书开放 API / 自备脚本 |
| FAQ ingest | 可选；路径自定 |
| machineId | `<MACHINE_ID>`（可选） |

## 换号

只需主机改指向本账号新例程的 url+auth；应用凭证可保留。

## 进行中

- （填写当前飞书群、跟进话题约定等非密钥信息）
