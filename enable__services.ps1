function Allow-Service {
    param (
        [int]$ServicePort,
        [string]$Protocol
    )
    $protocol = $Protocol.ToUpper()
    if ($protocol -eq "TCP" -or $protocol -eq "UDP") {
        New-NetFirewallRule -DisplayName "Allow Port $ServicePort $Protocol" -Direction Inbound -LocalPort $ServicePort -Protocol $Protocol -Action Allow
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
            Start-Service -Name "elasticsearch"
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

function Manage-Services {
    while ($true) {
        Write-Host "Select the services to allow or restore:"
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
                1 { Allow-Service -ServicePort 80 -Protocol "tcp"; Restore-Or-Start-Service -Service "drupal" }
                2 { Allow-Service -ServicePort 8080 -Protocol "tcp"; Restore-Or-Start-Service -Service "payroll" }
                3 { Allow-Service -ServicePort 21 -Protocol "tcp" }   # FTP
                4 { Allow-Service -ServicePort 22 -Protocol "tcp" }   # SSH
                5 { Allow-Service -ServicePort 6667 -Protocol "tcp" } # IRC
                6 { Allow-Service -ServicePort 3500 -Protocol "tcp" } # Metasploitable
                7 { Allow-Service -ServicePort 9200 -Protocol "tcp"; Restore-Or-Start-Service -Service "elasticsearch" }
                8 { Allow-Service -ServicePort 3389 -Protocol "tcp"; Restore-Or-Start-Service -Service "rdp" }
                9 { Allow-Service -ServicePort 445 -Protocol "tcp"; Restore-Or-Start-Service -Service "smb" }
                10 { Allow-Service -ServicePort 8585 -Protocol "tcp"; Restore-Or-Start-Service -Service "wordpress" }
                default { Write-Host "Invalid choice: $choice" }
            }
        }
        Write-Host "Completed your selections. Choose another service to allow/restore or press 'q' to quit."
    }
}

function Main {
    Manage-Services
}

Main
