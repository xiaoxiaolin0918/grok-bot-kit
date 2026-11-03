# 04 · 验收清单

勾选即过。本 kit **不含打印**。

## 角色与例程

- [ ] 侧栏仅人工创建了 **bot管家**；其余由管家 CreateAgent
- [ ] 飞书答疑 / 质量调度 / 代码审查 均已开工读包
- [ ] （可选）dev-cli 已开工
- [ ] **无**打印开发机器人被写入本对照表
- [ ] 巡检例程 09:06 / 21:06 Asia/Shanghai 已建
- [ ] 临时评审 / 群聊默认不在对照表

## 收口桥（bridge host）

- [ ] 主机为常开 Linux / macOS / Windows（不强制特定机型，非仅 Unix）
- [ ] `npm install` 完成；`config.example.json` 已复制为本地 config
- [ ] 密钥文件在 `~/.config/mac-bridge/`（或文档约定目录），权限收紧
- [ ] 进程守护已按 OS 选好：**systemd** / **launchd** / **NSSM 或任务计划程序**，飞书+yunxiao 自动拉起
- [ ] `GET /healthz` → 200
- [ ] 飞书私聊可唤醒飞书答疑；群未 @ 不唤醒
- [ ] 本机 smoke POST → 质量例程有记录

## Codeup

- [ ] 公网 `https://<BRIDGE_HOST>/yunxiao/codeup` 烟测 200
- [ ] Secret 与主机 ingress 一致；请求头为 **X-Codeup-Token**
- [ ] **先 smoke 再改远端** 已遵守
- [ ] 真实 MR Hook 能进质量调度（非仅 smoke）

## 安全

- [ ] git 状态无 secret / Bearer / 真实 webhook URL
- [ ] 角色模板无硬编码「唯一」agent id；写明以侧栏为准
- [ ] `<MACHINE_ID>` 仅在需要本机工具的角色填写，否则留空
- [ ] 换号检查清单：只改转发文件（见 `05-security.md`）

## 文档自检

- [ ] 同事仅凭本仓 docs + roles + mac-bridge README 可搭齐飞书+Codeup+巡检+四角色
- [ ] 文中未要求必须使用 Mac mini，且已写明 Windows 可用
