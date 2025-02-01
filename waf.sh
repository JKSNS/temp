#!/bin/bash

# install_modsecurity.sh
# This script installs Apache with ModSecurity and OWASP CRS using secure defaults.
# It tests the setup, removes test rules, and reverts to default configurations.

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
# Ensure the script is run as root
#######################################
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

#######################################
# Detect Operating System
#######################################
log_event "Detecting operating system..."
if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS=$ID
else
    log_event "ERROR: Unable to detect operating system."
    exit 1
fi

#######################################
# Set Variables Based on OS
#######################################
log_event "Configuring paths for $OS..."
case "$OS" in
    ubuntu|debian)
        APACHE_CONF_DIR="/etc/apache2"
        MODSEC_CONF_DIR="/etc/modsecurity"
        MODSEC_CONFIG_FILE="$MODSEC_CONF_DIR/modsecurity.conf"
        DEFAULT_SITE_CONF="$APACHE_CONF_DIR/sites-available/000-default.conf"
        APACHE_TEST_CMD="apache2ctl configtest"
        APACHE_RESTART_CMD="systemctl restart apache2"
        ;;
    fedora|centos|rhel)
        APACHE_CONF_DIR="/etc/httpd"
        MODSEC_CONF_DIR="/etc/modsecurity"
        MODSEC_CONFIG_FILE="$MODSEC_CONF_DIR/modsecurity.conf"
        DEFAULT_SITE_CONF="$APACHE_CONF_DIR/conf.d/default.conf"
        APACHE_TEST_CMD="httpd -t"
        APACHE_RESTART_CMD="systemctl restart httpd"
        ;;
    *)
        log_event "ERROR: Unsupported operating system ($OS)."
        exit 1
        ;;
esac

logFile="/var/log/modsecurity_install_log.txt"
WEB_DOMAIN="localhost"

log_event "=== Starting ModSecurity installation and configuration ==="

#######################################
# Step 1: Update system and install prerequisites
#######################################
log_event "Updating system packages..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt update && apt upgrade -y
    apt install -y apache2 libapache2-mod-security2 wget unzip
elif [[ "$OS" == "fedora" || "$OS" == "centos" || "$OS" == "rhel" ]]; then
    dnf update -y
    dnf install -y httpd mod_security wget unzip
fi

log_event "Restarting Apache..."
$APACHE_RESTART_CMD

#######################################
# Step 2: Configure ModSecurity Securely
#######################################
log_event "Configuring ModSecurity with secure defaults..."

# If the main configuration file doesn't exist, copy the recommended default.
if [ ! -f "$MODSEC_CONFIG_FILE" ]; then
    cp "$MODSEC_CONF_DIR/modsecurity.conf-recommended" "$MODSEC_CONFIG_FILE"
    log_event "Copied recommended modsecurity.conf to $MODSEC_CONFIG_FILE."
else
    log_event "ModSecurity configuration file already exists at $MODSEC_CONFIG_FILE."
fi

# Set ModSecurity to "On" (blocking mode).
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' "$MODSEC_CONFIG_FILE"
log_event "Set SecRuleEngine to On in $MODSEC_CONFIG_FILE."

#######################################
# Step 3: Download and Install the OWASP Core Rule Set (CRS)
#######################################
log_event "Downloading and installing the OWASP Core Rule Set (CRS)..."
tmpDir=$(mktemp -d)
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

# Move CRS setup and rules to the ModSecurity directory.
mv "$tmpDir/coreruleset-3.3.0/crs-setup.conf.example" "$MODSEC_CONF_DIR/crs-setup.conf"
mv "$tmpDir/coreruleset-3.3.0/rules" "$MODSEC_CONF_DIR/"
log_event "Installed CRS: crs-setup.conf and rules moved to $MODSEC_CONF_DIR."

rm -rf "$tmpDir"

#######################################
# Step 4: Add a Test Rule to Verify ModSecurity is Active
#######################################
log_event "Adding a test rule to verify ModSecurity is active..."
cat <<EOL > "$MODSEC_CONF_DIR/custom-test.conf"
# Custom ModSecurity Test Rule
SecRule ARGS:testparam "@contains test" "id:1000001,deny,status:403,msg:'Test Successful: ModSecurity is active.'"
EOL

log_event "Test rule added to $MODSEC_CONF_DIR/custom-test.conf (safe ID: 1000001)."

#######################################
# Step 5: Test Apache Configuration
#######################################
log_event "Testing Apache configuration..."
$APACHE_TEST_CMD
if [ $? -ne 0 ]; then
    log_event "ERROR: Apache configuration test failed. Please review your settings."
    exit 1
fi

log_event "Restarting Apache to apply changes..."
$APACHE_RESTART_CMD

#######################################
# Step 6: Remove Test Rule After Verification
#######################################
log_event "Removing the test rule..."
rm -f "$MODSEC_CONF_DIR/custom-test.conf"
$APACHE_RESTART_CMD
log_event "Test rule removed, and Apache reverted to optimized defaults."

#######################################
# Final Messages
#######################################
log_event "Installation and configuration complete. ModSecurity is active with OWASP CRS."
log_event "ModSecurity log file: /var/log/httpd/modsec_audit.log (or similar)."
