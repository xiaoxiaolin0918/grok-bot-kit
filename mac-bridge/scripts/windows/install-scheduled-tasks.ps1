#Requires -RunAsAdministrator
# 无 NSSM 时：用任务计划程序常驻（登录时启动；失败可按需在任务属性里设重启）
param(
  [string]$BridgeRoot = "",
  [string]$NodeBin = ""
)

$ErrorActionPreference = "Stop"
if (-not $BridgeRoot) {
  $BridgeRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $NodeBin) {
  $NodeBin = (Get-Command node -ErrorAction SilentlyContinue).Source
}
if (-not $NodeBin) { throw "找不到 node" }

$CfgDir = Join-Path $env:USERPROFILE ".config\mac-bridge"
$LogDir = Join-Path $CfgDir "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Cfg = Join-Path $CfgDir "config.json"
if (-not (Test-Path $Cfg)) { throw "缺少 $Cfg" }

function Register-BridgeTask([string]$TaskName, [string]$ScriptRel, [string]$LogLeaf) {
  $script = Join-Path $BridgeRoot $ScriptRel
  $outLog = Join-Path $LogDir "$LogLeaf.out.log"
  $errLog = Join-Path $LogDir "$LogLeaf.err.log"
  # cmd 包装便于重定向；MAC_BRIDGE_CONFIG 写入环境
  $arg = "/c set MAC_BRIDGE_CONFIG=$Cfg&& `"$NodeBin`" `"$script`" >> `"$outLog`" 2>> `"$errLog`""
  $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument $arg -WorkingDirectory $BridgeRoot
  $trigger = New-ScheduledTaskTrigger -AtLogOn
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
  $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
  Start-ScheduledTask -TaskName $TaskName
  Write-Host "registered $TaskName"
}

Register-BridgeTask "mac-bridge-feishu" "feishu\ws-long-connection.mjs" "feishu"
Register-BridgeTask "mac-bridge-yunxiao" "yunxiao\http-ingress.mjs" "yunxiao"
Write-Host "OK. 长期生产更建议 NSSM 服务。"
