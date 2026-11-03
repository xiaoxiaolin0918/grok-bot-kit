#Requires -RunAsAdministrator
# 用 NSSM 将飞书 WS / 云效 HTTP 注册为 Windows 服务
param(
  [string]$BridgeRoot = "",
  [string]$NodeBin = "",
  [string]$Nssm = "nssm"
)

$ErrorActionPreference = "Stop"
if (-not $BridgeRoot) {
  $BridgeRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $NodeBin) {
  $NodeBin = (Get-Command node -ErrorAction SilentlyContinue).Source
}
if (-not $NodeBin) { throw "找不到 node；请安装 Node>=18 或传入 -NodeBin" }

$CfgDir = Join-Path $env:USERPROFILE ".config\mac-bridge"
$LogDir = Join-Path $CfgDir "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Cfg = Join-Path $CfgDir "config.json"
if (-not (Test-Path $Cfg)) { throw "缺少 $Cfg ；先复制 config.example.json" }

function Install-BridgeService([string]$Name, [string]$ScriptRel) {
  $script = Join-Path $BridgeRoot $ScriptRel
  if (-not (Test-Path $script)) { throw "缺少 $script" }
  & $Nssm stop $Name 2>$null
  & $Nssm remove $Name confirm 2>$null
  & $Nssm install $Name $NodeBin $script
  & $Nssm set $Name AppDirectory $BridgeRoot
  & $Nssm set $Name AppEnvironmentExtra "MAC_BRIDGE_CONFIG=$Cfg"
  & $Nssm set $Name AppStdout (Join-Path $LogDir "$Name.out.log")
  & $Nssm set $Name AppStderr (Join-Path $LogDir "$Name.err.log")
  & $Nssm set $Name AppRotateFiles 1
  & $Nssm set $Name Start SERVICE_AUTO_START
  & $Nssm set $Name AppExit Default Restart
  & $Nssm set $Name AppRestartDelay 3000
  & $Nssm start $Name
  Write-Host "started service $Name"
}

Install-BridgeService "mac-bridge-feishu" "feishu\ws-long-connection.mjs"
Install-BridgeService "mac-bridge-yunxiao" "yunxiao\http-ingress.mjs"
Write-Host "OK. Logs: $LogDir"
Write-Host "可选：同样用 NSSM 为 frpc.exe 建服务（配置勿进 git）"
