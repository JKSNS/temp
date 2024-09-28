function Enable-FirewallRule {
    param (
        [int]$ServicePort,
        [string]$Protocol
    )
    $protocol = $Protocol.ToUpper()
    if ($protocol -eq "TCP" -or $protocol -eq "UDP") {
        # Use netsh to add a rule that allows the port for the specific protocol
        $command = "netsh advfirewall firewall add rule name=`"Allow Port $ServicePort $protocol`" dir=in action=allow protocol=$protocol localport=$ServicePort"
        Invoke-Expression $command
        Write-Host "Allowed $ServicePort/$Protocol."
    } else {
        Write-Host "Invalid protocol specified: $Protocol"
    }
}

function Restore-Or-Start-Service {
    param (
        [string]$Service
    )
    switch ($Service.ToLower()) {
        "drupal" {
            Write-Host "Starting Drupal service..."
            Start-Service -Name "W3SVC"
            Write-Host "Restoring Drupal website..."
            "<h1>Site Restored!</h1><p>The site is back online.</p>" | Out-File "C:\inetpub\wwwroot\index.html" -Encoding UTF8
        }
        "payroll" {
            Write-Host "Starting Payroll website service..."
            Start-Service -Name "W3SVC"
            Write-Host "Restoring Payroll website..."
            "<h1>Payroll Site Restored!</h1><p>The site is back online.</p>" | Out-File "C:\inetpub\wwwroot\payroll\index.html" -Encoding UTF8
        }
        "elasticsearch" {
            Write-Host "Starting Elasticsearch service..."
            Start-Service -Name "elasticsearch-service-x64"
            Write-Host "Elasticsearch service started."
        }
        "wordpress" {
            Write-Host "Starting WordPress service..."
            Start-Service -Name "W3SVC"
            Write-Host "Restoring WordPress site..."
            "<h1>WordPress Site Restored!</h1><p>The site is back online.</p>" | Out-File "C:\inetpub\wwwroot\wordpress\index.html" -Encoding UTF8
        }
        "rdp" {
            Write-Host "Enabling RDP service..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
            Write-Host "RDP service enabled."
        }
        "smb" {
            Write-Host "Starting SMB service..."
            Start-Service -Name "LanmanServer"
            Write-Host "SMB service started."
        }
        default {
            Write-Host "Invalid service choice for restoration or starting."
        }
    }
}

function Enable-All-Services-And-FirewallRules {
    # Automatically enable firewall rules and restore all services
    Enable-FirewallRule -ServicePort 80 -Protocol "tcp"; Restore-Or-Start-Service -Service "drupal"
    Enable-FirewallRule -ServicePort 8080 -Protocol "tcp"; Restore-Or-Start-Service -Service "payroll"
    Enable-FirewallRule -ServicePort 21 -Protocol "tcp"    # FTP
    Enable-FirewallRule -ServicePort 22 -Protocol "tcp"    # SSH
    Enable-FirewallRule -ServicePort 6667 -Protocol "tcp"  # IRC
    Enable-FirewallRule -ServicePort 3500 -Protocol "tcp"  # Metasploitable
    Enable-FirewallRule -ServicePort 9200 -Protocol "tcp"; Restore-Or-Start-Service -Service "elasticsearch"
    Enable-FirewallRule -ServicePort 3389 -Protocol "tcp"; Restore-Or-Start-Service -Service "rdp"
    Enable-FirewallRule -ServicePort 445 -Protocol "tcp"; Restore-Or-Start-Service -Service "smb"
    Enable-FirewallRule -ServicePort 8585 -Protocol "tcp"; Restore-Or-Start-Service -Service "wordpress"
}

function Main {
    Enable-All-Services-And-FirewallRules
}

Main
