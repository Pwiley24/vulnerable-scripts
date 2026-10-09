# Quick verification script for CyberPatriot Windows scenario setup
# Run as Administrator

Write-Host "`n=== USERS ===" -ForegroundColor Cyan
Get-LocalUser | Select Name, Enabled, PasswordLastSet | Format-Table -AutoSize

Write-Host "=== ADMINISTRATORS GROUP ===" -ForegroundColor Cyan
Get-LocalGroupMember -Group "Administrators" | Select Name, ObjectClass | Format-Table -AutoSize

Write-Host "=== EXPECTED ACCOUNTS CHECK ===" -ForegroundColor Cyan
$expected = @("ITAdmin","HRUser01")
$unauthorized = @("svc_monitor","TempUser123","SysAdminBackup")
foreach ($u in $expected) {
    $exists = Get-LocalUser -Name $u -ErrorAction SilentlyContinue
    Write-Host "$u (should exist): $(if ($exists) {'FOUND'} else {'MISSING'})"
}
foreach ($u in $unauthorized) {
    $exists = Get-LocalUser -Name $u -ErrorAction SilentlyContinue
    Write-Host "$u (backdoor, should exist pre-fix): $(if ($exists) {'FOUND'} else {'NOT FOUND'})"
}

Write-Host "`n=== DEFENDER ===" -ForegroundColor Cyan
try {
    Get-MpComputerStatus | Select RealTimeProtectionEnabled, AMServiceEnabled, IsTamperProtected | Format-Table -AutoSize
} catch { Write-Host "Could not query Defender status: $($_.Exception.Message)" }

Write-Host "=== FIREWALL ===" -ForegroundColor Cyan
Get-NetFirewallProfile | Select Name, Enabled | Format-Table -AutoSize

Write-Host "=== RDP ===" -ForegroundColor Cyan
$rdp = Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue
Write-Host "fDenyTSConnections: $($rdp.fDenyTSConnections)  (0 = RDP enabled)"
Get-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Select DisplayName, Enabled | Format-Table -AutoSize

Write-Host "=== SCHEDULED TASKS (non-Microsoft) ===" -ForegroundColor Cyan
Get-ScheduledTask | Where TaskPath -notlike '\Microsoft\*' |
    Select TaskName, State, @{n='RunAs';e={$_.Principal.UserId}} | Format-Table -AutoSize

Write-Host "=== REGISTRY RUN KEYS ===" -ForegroundColor Cyan
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue |
    Select * -ExcludeProperty PS* | Format-List

Write-Host "=== PASSWORD POLICY ===" -ForegroundColor Cyan
net accounts

Write-Host "=== PERSISTENCE OUTPUT FILES ===" -ForegroundColor Cyan
foreach ($f in "C:\temp\persistence.txt","C:\temp\autorun.txt") {
    if (Test-Path $f) { Write-Host "$f : EXISTS -> $(Get-Content $f)" }
    else { Write-Host "$f : not present (task may not have triggered yet, or C:\temp missing)" }
}

Write-Host "=== README FILES ===" -ForegroundColor Cyan
foreach ($r in "$env:PUBLIC\Desktop\README.txt","C:\Users\Public\Desktop\README-Incident.txt") {
    Write-Host "$r : $(if (Test-Path $r) {'EXISTS'} else {'MISSING'})"
}

Write-Host "`n=== SETUP LOG ERRORS ===" -ForegroundColor Cyan
if (Test-Path C:\setup_log_cyberpatriot.txt) {
    Select-String "Error" C:\setup_log_cyberpatriot.txt
    if (-not (Select-String "Error" C:\setup_log_cyberpatriot.txt)) { Write-Host "No errors logged." }
} else {
    Write-Host "Log file not found."
}

Write-Host "`n=== DONE ===" -ForegroundColor Green
