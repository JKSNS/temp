'${message}' | Out-File -FilePath 'C:\msg.txt'
schtasks /create /tn $(-join ((65..90) + (97..122) | Get-Random -Count 8 | % {[char]$_})) /tr 'notepad.exe C:\msg.txt' /sc once /st $(Get-Date).AddMinutes(1).ToString('HH:mm') /ru $(((quser | Select-Object -Skip 1 -First 1) -split '\s\s+')[0].TrimStart(' '))
