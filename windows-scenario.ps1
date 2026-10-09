# CyberPatriot Windows Incident Response Scenario Setup Script
# Unique for Grissom JROTC CyberPatriot Training

$ErrorActionPreference = "Stop"

# --- Customizable Variables ---
$PrimaryUser = "ITAdmin"
$PrimaryPass = "Company2023!"
$BackdoorUser = "svc_monitor"
$BackdoorPass = "SvcMonitor!2024"
$LogFile = "C:\setup_log_cyberpatriot.txt"
$ReadmePath = "$env:PUBLIC\Desktop\README.txt"

function Log-Step($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $LogFile -Append
}

# 0. Ensure C:\temp exists (persistence payloads below write here)
New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null

# 1. Create the authorized admin account (this was missing /add before)
Log-Step "Creating primary admin user..."
if (-not (Get-LocalUser -Name $PrimaryUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $PrimaryUser -Password (ConvertTo-SecureString $PrimaryPass -AsPlainText -Force) -FullName "IT Admin" -ErrorAction Stop
    Add-LocalGroupMember -Group "Administrators" -Member $PrimaryUser -ErrorAction Stop
} else {
    Set-LocalUser -Name $PrimaryUser -Password (ConvertTo-SecureString $PrimaryPass -AsPlainText -Force)
}

# 2. Create Backdoor User
Log-Step "Creating backdoor user..."
if (-not (Get-LocalUser -Name $BackdoorUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $BackdoorUser -Password (ConvertTo-SecureString $BackdoorPass -AsPlainText -Force) -FullName "Service Monitor" -ErrorAction Stop
    Add-LocalGroupMember -Group "Administrators" -Member $BackdoorUser -ErrorAction Stop
}

# 3. Disable Security Features
# NOTE: Tamper Protection (on by default on current Windows) silently blocks this.
# Turn Tamper Protection off manually in Windows Security before running, or these
# two lines will appear to succeed but have no effect.
Log-Step "Disabling Defender and Firewall..."
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 4. Add Malicious Scheduled Task
Log-Step "Adding malicious scheduled task..."
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"Start-Sleep 60; Add-Content C:\temp\persistence.txt 'Persistence Active'`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "SystemMonitorUpdate" -Action $Action -Trigger $Trigger -User "SYSTEM" -RunLevel Highest -Force

# 5. Registry Autorun
Log-Step "Adding registry autorun..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Updater" -Value "powershell.exe -NoProfile -WindowStyle Hidden -Command `"Start-Sleep 30; Add-Content C:\temp\autorun.txt 'Autorun Active'`""

# 6. Create Competition README
Log-Step "Creating README.txt on desktop..."
@"
====================================================
Enterprise Workstation Compromise - Incident Response Scenario

You are the security analyst for a small business. The workstation has been compromised. Your tasks:
- Remove all unauthorized users and persistence mechanisms
- Re-enable security features (Defender, Firewall)
- Harden system settings per company policy
- Answer forensic questions in this README

AUTHORIZED USERS:
- $PrimaryUser (IT Admin)

FORENSIC QUESTIONS:
1. What persistence mechanisms did the attacker use?
2. Which registry keys were modified for persistence?
3. What password policy is currently enforced?

Good luck!
====================================================
"@ | Out-File -FilePath $ReadmePath -Encoding UTF8

Log-Step "Setup complete. VM is ready for CyberPatriot training."
Write-Host "Setup complete. Review $ReadmePath for scenario details."
Write-Host "Please SHUT DOWN the VM now and take a snapshot."
