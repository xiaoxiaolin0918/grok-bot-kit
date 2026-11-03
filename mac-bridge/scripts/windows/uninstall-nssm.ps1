#Requires -RunAsAdministrator
param([string]$Nssm = "nssm")
$ErrorActionPreference = "Continue"
foreach ($Name in @("mac-bridge-feishu", "mac-bridge-yunxiao", "mac-bridge-frpc")) {
  & $Nssm stop $Name 2>$null
  & $Nssm remove $Name confirm 2>$null
  Write-Host "removed $Name"
}
