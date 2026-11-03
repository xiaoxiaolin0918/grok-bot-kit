# Windows 进程守护（bridge host）

Node 脚本与 Linux/macOS **相同**。本目录只解决「开机常驻 / 崩溃拉起」。

任选其一：

| 方式 | 适用 | 脚本 |
|------|------|------|
| **NSSM** | 推荐；注册为 Windows 服务 | `install-nssm.ps1` / `uninstall-nssm.ps1` |
| **任务计划程序** | 无 NSSM 时 | `install-scheduled-tasks.ps1` / `uninstall-scheduled-tasks.ps1` |

## 前置

1. 安装 [Node.js](https://nodejs.org/) ≥ 18，确认 `node -v`
2. 在本机打开 `mac-bridge` 目录执行 `npm install --omit=dev`
3. 填好 `%USERPROFILE%\.config\mac-bridge\config.json` 与各密钥文件
4. **管理员 PowerShell** 运行安装脚本（改服务/计划任务通常需要提升权限）

先改脚本顶部的 `$BridgeRoot`、`$NodeBin`（若 node 不在 PATH）。

## NSSM

1. 下载 [NSSM](https://nssm.cc/) ，把 `nssm.exe` 放到 PATH 或改 `$Nssm`
2. `.\install-nssm.ps1`
3. 服务名默认：`mac-bridge-feishu`、`mac-bridge-yunxiao`
4. 日志目录：`%USERPROFILE%\.config\mac-bridge\logs\`

卸载：`.\uninstall-nssm.ps1`

## 任务计划程序

`.\install-scheduled-tasks.ps1` 会创建「登录时 / 启动时」运行的任务，并打开「失败重启」相关设置（见脚本注释）。

适合临时或不便装 NSSM 的机器；长期更建议 NSSM 服务。

## 公网

与 Unix 相同：本机 `8787` + frpc/cloudflared/ngrok。frpc 可用 NSSM 再挂一个服务，或单独计划任务。

## 验收

```powershell
curl.exe -sS http://127.0.0.1:8787/healthz
# 或在 Git Bash 中跑 ..\smoke-test.sh
```
