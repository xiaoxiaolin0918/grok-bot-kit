#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
foreach ($TaskName in @("mac-bridge-feishu", "mac-bridge-yunxiao", "mac-bridge-frpc")) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
  Write-Host "removed task $TaskName"
}
