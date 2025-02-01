#!/bin/bash
#
# install_modsecurity.sh
#
# This script installs Apache with ModSecurity (including the OWASP Core Rule Set)
# using secure defaults that help protect against common attacks like XSS and SQL Injection.
#
# It will prompt you for a few options (like your web server's domain or IP and file locations)
# but uses secure defaults if you just press Enter.
#
# IMPORTANT: Run this script as root or with sudo privileges.
#
# Logs are saved to /var/log/modsecurity_install_log.txt

#######################################
# Function: log_event
# Logs messages with a timestamp.
#######################################
log_event() {
    local now
    now=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$now - $1" | tee -a "$logFile"
}

#######################################
# Check for root/sudo privileges
#######################################
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

#######################################
# Set default values and prompt for input
#######################################
# Default web server domain/IP (used in the test message)
read -p "Enter your web server domain or IP address (default: localhost): " WEB_DOMAIN
WEB_DOMAIN=${WEB_DOMAIN:-localhost}

# Default ModSecurity configuration directory
read -p "Enter the ModSecurity configuration directory (default: /etc/modsecurity): " modsecConfDir
modsecConfDir=${modsecConfDir:-/etc/modsecurity}

# Default Apache site configuration file location
read -p "Enter the path to your default Apache site config (default: /etc/apache2/sites-available/000-default.conf): " defaultSiteConf
defaultSiteConf=${defaultSiteConf:-/etc/apache2/sites-available/000-default.conf}

# Set the ModSecurity main configuration file path
modsecConfigFile="$modsecConfDir/modsecurity.conf"

# Apache mod_security include file (where additional config lines are added)
apacheModsConf="/etc/apache2/mods-enabled/security2.conf"

# Log file location
logFile="/var/log/modsecurity_install_log.txt"

log_event "=== Starting ModSecurity installation and configuration ==="

#######################################
# Step 1: Update system and install prerequisites
#######################################
log_event "Updating system packages..."
apt update && apt upgrade -y

log_event "Installing Apache, ModSecurity, wget, and unzip..."
apt install -y apache2 libapache2-mod-security2 wget unzip

log_event "Restarting Apache..."
systemctl restart apache2

#######################################
# Step 2: Configure ModSecurity securely
#######################################
log_event "Configuring ModSecurity with secure defaults..."
# Copy the recommended config if the main config file is not already set up.
if [ ! -f "$modsecConfigFile" ]; then
    cp "$modsecConfDir/modsecurity.conf-recommended" "$modsecConfigFile"
    log_event "Copied recommended modsecurity.conf to $modsecConfigFile."
else
    log_event "ModSecurity config file already exists at $modsecConfigFile."
fi

# Set ModSecurity to "On" (blocking mode) instead of just detecting issues.
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' "$modsecConfigFile"
log_event "Set SecRuleEngine to On in $modsecConfigFile."

#######################################
# Step 3: Download and install the OWASP Core Rule Set (CRS)
#######################################
log_event "Downloading the OWASP Core Rule Set (CRS)..."
# Create a temporary directory for the download
tmpDir=$(mktemp -d)
# Download the CRS (version 3.3.0 is used here; update URL if needed)
CRS_URL="https://github.com/coreruleset/coreruleset/archive/v3.3.0.zip"
CRS_ZIP="$tmpDir/coreruleset-3.3.0.zip"
wget -O "$CRS_ZIP" "$CRS_URL"
if [ $? -ne 0 ]; then
    log_event "ERROR: Could not download CRS from $CRS_URL."
    exit 1
fi
log_event "Downloaded CRS to $CRS_ZIP."

log_event "Unzipping the CRS package..."
unzip "$CRS_ZIP" -d "$tmpDir"
if [ $? -ne 0 ]; then
    log_event "ERROR: Failed to unzip the CRS package."
    exit 1
fi

# Move the example CRS setup file and the rules directory into the ModSecurity directory.
mv "$tmpDir/coreruleset-3.3.0/crs-setup.conf.example" "$modsecConfDir/crs-setup.conf"
mv "$tmpDir/coreruleset-3.3.0/rules" "$modsecConfDir/"
log_event "Installed CRS: crs-setup.conf and rules moved to $modsecConfDir."

# Clean up temporary files
rm -rf "$tmpDir"

#######################################
# Step 4: Update Apache configuration to load ModSecurity and CRS rules
#######################################
log_event "Updating Apache mod_security configuration to include CRS rules..."
# Ensure Apache loads all .conf files from the ModSecurity directory.
if ! grep -q "IncludeOptional ${modsecConfDir}/*.conf" "$apacheModsConf"; then
    echo "IncludeOptional ${modsecConfDir}/*.conf" >> "$apacheModsConf"
    log_event "Added: IncludeOptional ${modsecConfDir}/*.conf"
fi

# Ensure Apache loads all the CRS rules.
if ! grep -q "Include ${modsecConfDir}/rules/*.conf" "$apacheModsConf"; then
    echo "Include ${modsecConfDir}/rules/*.conf" >> "$apacheModsConf"
    log_event "Added: Include ${modsecConfDir}/rules/*.conf"
fi

#######################################
# Step 5: Add a simple test rule to verify ModSecurity is working
#######################################
log_event "Adding a test rule to verify ModSecurity is active..."
# The test rule below will block any request containing the parameter ?testparam=test.
# It is inserted just before the closing </VirtualHost> tag in your default Apache site config.
if ! grep -q "id:999" "$defaultSiteConf"; then
    sed -i "/<\/VirtualHost>/ i\\
<IfModule security2_module>\\
    SecRuleEngine On\\
    SecRule ARGS:testparam \"@contains test\" \"id:999,deny,status:403,msg:'Test Successful: ModSecurity is active.'\"\\
</IfModule>" "$defaultSiteConf"
    log_event "Test rule added to $defaultSiteConf. (Try accessing: http://${WEB_DOMAIN}/?testparam=test)"
else
    log_event "Test rule already exists in $defaultSiteConf."
fi

#######################################
# Step 6: Test Apache configuration and restart Apache
#######################################
log_event "Testing Apache configuration..."
apache2ctl configtest
if [ $? -ne 0 ]; then
    log_event "ERROR: Apache configuration test failed. Please review your settings."
    exit 1
fi

log_event "Restarting Apache to apply changes..."
systemctl restart apache2

#######################################
# Final messages
#######################################
log_event "Installation and configuration complete."
log_event "To test your setup, open a browser and visit: http://${WEB_DOMAIN}/?testparam=test"
log_event "You should receive a 403 Forbidden response, and the Apache error log (typically /var/log/apache2/error.log) should show the 'Test Successful' message."
log_event "Remember: Once testing is complete, consider removing or commenting out the test rule from $defaultSiteConf."

echo "ModSecurity installation and setup completed successfully. See the log at $logFile for details."
