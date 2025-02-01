#!/bin/bash
# install_modsecurity.sh
#
# This script installs and configures Apache with ModSecurity and the OWASP CRS,
# and then adds a temporary test rule to verify that ModSecurity is working.
#
# IMPORTANT: Run this script as a user with sudo privileges.
#
# Logs are stored in /var/log/modsecurity_install_log.txt

# Define variables
modsecConfDir="/etc/modsecurity"
modsecConfigFile="$modsecConfDir/modsecurity.conf"
apacheModsConf="/etc/apache2/mods-enabled/security2.conf"
defaultSiteConf="/etc/apache2/sites-available/000-default.conf"
logFile="/var/log/modsecurity_install_log.txt"

# Function to log events (updates current date/time for each log entry)
log_event() {
    local now
    now=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$now - $1" | tee -a "$logFile"
}

# Ensure the script is run as root or with sudo privileges.
if [ "$EUID" -ne 0 ]; then
    log_event "Please run as root or use sudo."
    exit 1
fi

log_event "=== Starting ModSecurity installation and configuration ==="

###############################################################################
# Step 1: Update System and Install Apache with ModSecurity and prerequisites
###############################################################################
log_event "Updating system packages..."
apt update && apt upgrade -y

log_event "Installing Apache, ModSecurity, wget, and unzip..."
apt install -y apache2 libapache2-mod-security2 wget unzip

log_event "Restarting Apache..."
systemctl restart apache2

###############################################################################
# Step 2: Enable and Configure ModSecurity
###############################################################################
log_event "Configuring ModSecurity..."

# Copy the recommended configuration file if not already present.
if [ ! -f "$modsecConfigFile" ]; then
    cp "$modsecConfDir/modsecurity.conf-recommended" "$modsecConfigFile"
    log_event "Copied modsecurity.conf-recommended to $modsecConfigFile."
else
    log_event "ModSecurity configuration file already exists at $modsecConfigFile."
fi

# Change the SecRuleEngine from "DetectionOnly" to "On" (enable blocking)
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' "$modsecConfigFile"
log_event "Updated SecRuleEngine to On in $modsecConfigFile."

###############################################################################
# Step 3: Download and Install the OWASP Core Rule Set (CRS)
###############################################################################
log_event "Downloading and installing the OWASP Core Rule Set (CRS)..."
# Create a temporary directory for CRS download
tmpDir=$(mktemp -d)

# Download CRS v3.3.0 (adjust URL if a newer version is needed)
CRS_URL="https://github.com/coreruleset/coreruleset/archive/v3.3.0.zip"
CRS_ZIP="$tmpDir/coreruleset-3.3.0.zip"

wget -O "$CRS_ZIP" "$CRS_URL"
if [ $? -ne 0 ]; then
    log_event "ERROR: Failed to download CRS from $CRS_URL."
    exit 1
fi

# Unzip the downloaded file
unzip "$CRS_ZIP" -d "$tmpDir"
if [ $? -ne 0 ]; then
    log_event "ERROR: Failed to unzip $CRS_ZIP."
    exit 1
fi

# Move the CRS setup file and rules into the ModSecurity configuration directory
mv "$tmpDir/coreruleset-3.3.0/crs-setup.conf.example" "$modsecConfDir/crs-setup.conf"
mv "$tmpDir/coreruleset-3.3.0/rules" "$modsecConfDir/"
log_event "OWASP CRS installed in $modsecConfDir (rules in $modsecConfDir/rules)."

# Clean up temporary files
rm -rf "$tmpDir"

###############################################################################
# Step 4: Update Apache Configuration to Load ModSecurity and CRS Rules
###############################################################################
log_event "Updating Apache configuration to include ModSecurity and CRS rules..."

# Ensure that the Apache mod_security configuration includes the following lines.
# These lines will load any .conf files in /etc/modsecurity and the CRS rules.
if ! grep -q "IncludeOptional /etc/modsecurity/*.conf" "$apacheModsConf"; then
    echo "IncludeOptional /etc/modsecurity/*.conf" >> "$apacheModsConf"
    log_event "Added 'IncludeOptional /etc/modsecurity/*.conf' to $apacheModsConf."
fi

if ! grep -q "Include /etc/modsecurity/rules/*.conf" "$apacheModsConf"; then
    echo "Include /etc/modsecurity/rules/*.conf" >> "$apacheModsConf"
    log_event "Added 'Include /etc/modsecurity/rules/*.conf' to $apacheModsConf."
fi

###############################################################################
# Step 5: Add a Test Rule to Verify ModSecurity Functionality
###############################################################################
log_event "Adding a temporary test rule to the default Apache site for verification..."
# The test rule will deny requests with the parameter ?testparam=test
# It is added within an <IfModule> block to ensure it only applies if mod_security is enabled.
if ! grep -q "id:999" "$defaultSiteConf"; then
    sed -i '/<\/VirtualHost>/i \
    <IfModule security2_module>\n\
        SecRuleEngine On\n\
        SecRule ARGS:testparam "@contains test" "id:999,deny,status:403,msg:\'Test Successful\'"\n\
    </IfModule>\n' "$defaultSiteConf"
    log_event "Test rule added to $defaultSiteConf. (Requests with ?testparam=test will be blocked.)"
else
    log_event "Test rule already exists in $defaultSiteConf."
fi

###############################################################################
# Step 6: Test Apache Configuration and Restart Apache
###############################################################################
log_event "Testing Apache configuration..."
apache2ctl configtest
if [ $? -ne 0 ]; then
    log_event "ERROR: Apache configuration test failed. Please review the configuration."
    exit 1
fi

log_event "Restarting Apache..."
systemctl restart apache2

###############################################################################
# Final Message
###############################################################################
log_event "ModSecurity installation and configuration completed successfully."
log_event "To test, visit your server with a URL such as: http://your_server_ip/?testparam=test"
log_event "A 403 Forbidden response with 'Test Successful' in the logs should indicate the test rule is active."
log_event "Remember to remove or comment out the test rule from $defaultSiteConf after testing."

echo "ModSecurity installation and setup completed successfully. See log at $logFile."
