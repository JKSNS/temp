function Block-Service {
    param (
        [int]$ServicePort
    )
    # Block both TCP and UDP
    $protocols = @("TCP", "UDP")
    foreach ($protocol in $protocols) {
        # Remove any existing rule allowing the port for the specific protocol
        $removeAllowRule = "netsh advfirewall firewall delete rule name=`"Allow Port $ServicePort $protocol`" protocol=$protocol localport=$ServicePort"
        Invoke-Expression $removeAllowRule

        # Add rule to block the port for the specific protocol
        $blockCommand = "netsh advfirewall firewall add rule name=`"Block Port $ServicePort $protocol`" dir=in action=block protocol=$protocol localport=$ServicePort"
        Invoke-Expression $blockCommand

        Write-Host "Blocked $ServicePort/$protocol and removed any existing allow rules."
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
                1 { Block-Service -ServicePort 80 -Protocol "tcp"; Deface-Or-Stop-Service -Service "drupal" }
                2 { Block-Service -ServicePort 8080 -Protocol "tcp"; Deface-Or-Stop-Service -Service "payroll" }
                3 { Block-Service -ServicePort 21 -Protocol "tcp" }   # FTP
                4 { Block-Service -ServicePort 22 -Protocol "tcp" }   # SSH
                5 { Block-Service -ServicePort 6667 -Protocol "tcp" } # IRC
                6 { Block-Service -ServicePort 3500 -Protocol "tcp" } # Metasploitable
                7 { Block-Service -ServicePort 9200 -Protocol "tcp"; Deface-Or-Stop-Service -Service "elasticsearch" }
                8 { Block-Service -ServicePort 3389 -Protocol "tcp"; Deface-Or-Stop-Service -Service "rdp" }
                9 { Block-Service -ServicePort 445 -Protocol "tcp"; Deface-Or-Stop-Service -Service "smb" }
                10 { Block-Service -ServicePort 8585 -Protocol "tcp"; Deface-Or-Stop-Service -Service "wordpress" }
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
