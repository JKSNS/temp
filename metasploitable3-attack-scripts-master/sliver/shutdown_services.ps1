function Disable-FirewallRule {
    param (
        [int]$ServicePort
    )
    $protocols = @("TCP", "UDP")
    foreach ($protocol in $protocols) {
        $disableRule = "netsh advfirewall firewall set rule name=`"Allow Port $ServicePort $protocol`" new enable=no"
        $disableBlockRule = "netsh advfirewall firewall set rule name=`"Block Port $ServicePort $protocol`" new enable=no"
        try {
            Invoke-Expression $disableRule
            Write-Host "Disabled allow rule for port $ServicePort/$protocol."
        } catch {
            Write-Host "No allow rule found for port $ServicePort/$protocol."
        }
        try {
            Invoke-Expression $disableBlockRule
            Write-Host "Disabled block rule for port $ServicePort/$protocol."
        } catch {
            Write-Host "No block rule found for port $ServicePort/$protocol."
        }
    }
}

function Deface-Or-Stop-Service {
    param (
        [string]$Service
    )
    switch ($Service.ToLower()) {
        "drupal" {
            Write-Host "Stopping Drupal service..."
            Stop-Service -Name "W3SVC" -Force
            Write-Host "Defacing Drupal website..."
            "<h1>Site Defaced!</h1><p>This site has been hacked.</p>" | Out-File "C:\inetpub\wwwroot\index.html" -Encoding UTF8
        }
        "payroll" {
            Write-Host "Stopping Payroll website service..."
            Stop-Service -Name "W3SVC" -Force
            
            $payrollPath = "C:\inetpub\wwwroot\payroll"
            if (-not (Test-Path -Path $payrollPath)) {
                Write-Host "Creating Payroll directory..."
                New-Item -ItemType Directory -Path $payrollPath
            }
            
            Write-Host "Defacing Payroll website..."
            "<h1>Payroll Site Down!</h1><p>Maintenance in progress.</p>" | Out-File "$payrollPath\index.html" -Encoding UTF8
        }
        "elasticsearch" {
            Write-Host "Stopping Elasticsearch service..."
            Stop-Service -Name "elasticsearch-service-x64" -Force
            Write-Host "Elasticsearch service stopped."
        }
        "wordpress" {
            Write-Host "Stopping WordPress service..."
            Stop-Service -Name "W3SVC" -Force
            Write-Host "Defacing WordPress site..."
            "<h1>WordPress Site Defaced!</h1><p>Unauthorized Access Detected.</p>" | Out-File "C:\inetpub\wwwroot\wordpress\index.html" -Encoding UTF8
        }
        "rdp" {
            Write-Host "Disabling RDP service..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
            Write-Host "RDP service disabled."
        }
        "smb" {
            Write-Host "Stopping SMB service..."
            Stop-Service -Name "LanmanServer" -Force
            Write-Host "SMB service stopped."
        }
        default {
            Write-Host "Invalid service choice for defacement or stopping."
        }
    }
}

function Manage-Services {
    while ($true) {
        Write-Host "Select the services to disable or deface:"
        Write-Host "1) Drupal website (port 80)"
        Write-Host "2) Payroll website app (port 8080)"
        Write-Host "3) FTP service (port 21)"
        Write-Host "4) SSH (port 22)"
        Write-Host "5) IRC (port 6667)"
        Write-Host "6) Metasploitable info page (port 3500)"
        Write-Host "7) Elasticsearch"
        Write-Host "8) RDP"
        Write-Host "9) SMB"
        Write-Host "10) WordPress"
        Write-Host "Enter 'q' to quit."

        $choices = Read-Host "Enter your choices"
        if ($choices -eq 'q') {
            Write-Host "Exiting script."
            break
        }

        $choice_array = $choices -split '\s+'
        foreach ($choice in $choice_array) {
            switch ($choice) {
                1 { Disable-FirewallRule -ServicePort 80; Deface-Or-Stop-Service -Service "drupal" }
                2 { Disable-FirewallRule -ServicePort 8080; Deface-Or-Stop-Service -Service "payroll" }
                3 { Disable-FirewallRule -ServicePort 21 }   # FTP
                4 { Disable-FirewallRule -ServicePort 22 }   # SSH
                5 { Disable-FirewallRule -ServicePort 6667 } # IRC
                6 { Disable-FirewallRule -ServicePort 3500 } # Metasploitable
                7 { Disable-FirewallRule -ServicePort 9200; Deface-Or-Stop-Service -Service "elasticsearch" }
                8 { Disable-FirewallRule -ServicePort 3389; Deface-Or-Stop-Service -Service "rdp" }
                9 { Disable-FirewallRule -ServicePort 445; Deface-Or-Stop-Service -Service "smb" }
                10 { Disable-FirewallRule -ServicePort 8585; Deface-Or-Stop-Service -Service "wordpress" }
                default { Write-Host "Invalid choice: $choice" }
            }
        }
        Write-Host "Completed your selections. Choose another service to disable/deface or press 'q' to quit."
    }
}

function Main {
    Manage-Services
}

Main
