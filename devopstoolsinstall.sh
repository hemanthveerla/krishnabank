#!/bin/bash

echo "===================================================="
echo " DevOps Interactive Installation Script"
echo " Java17 + Java21 + Jenkins + Docker + SonarQube + Tomcat + Apache HTTPD"
echo "===================================================="

# ------------------------------------------------
# Variables
# ------------------------------------------------

SONAR_VERSION="10.7.0.96327"
SONAR_ZIP="sonarqube-${SONAR_VERSION}.zip"
SONAR_DIR="/opt/sonarqube-${SONAR_VERSION}"
SONAR_LINK="/opt/sonarqube"

TOMCAT_VERSION="9.0.102"
TOMCAT_FILE="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/${TOMCAT_FILE}"
TOMCAT_HOME="/opt/tomcat"

# New Apache Variable
APACHE_HOME="/opt/apache"

JAVA17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64"
JAVA21_HOME="/usr/lib/jvm/java-21-amazon-corretto.x86_64"

INSTALL_ALL="no"

# ------------------------------------------------
# Get Public IP
# ------------------------------------------------

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="<EC2-PUBLIC-IP>"
fi

# ------------------------------------------------
# Helper Functions
# ------------------------------------------------

ask_yes_no() {
    read -p "$1 yes/no: " choice
    case "$choice" in
        yes|y|YES|Y) return 0 ;;
        no|n|NO|N) return 1 ;;
        *) echo "Invalid input. Considering as no."; return 1 ;;
    esac
}

ask_install() {
    if [ "$INSTALL_ALL" == "yes" ]; then return 0; fi
    ask_yes_no "Do you want to install $1?"
    return $?
}

# ------------------------------------------------
# Install All Option
# ------------------------------------------------

if ask_yes_no "Do you want to install all tools?"; then
    INSTALL_ALL="yes"
    echo "You selected install all tools."
else
    INSTALL_ALL="no"
    echo "You selected custom installation."
fi

# ... [System Details & Basic Packages blocks remain same as your original] ...

yum install -y wget curl git unzip tar lsof net-tools fontconfig ca-certificates
update-ca-trust

# ... [Java, Maven, Docker, Jenkins, SonarQube blocks remain same] ...

# ------------------------------------------------
# Apache HTTPD Installation (New Section)
# ------------------------------------------------

if ask_install "Apache HTTPD (2.4)"; then
    echo ""
    echo "Installing Apache HTTPD..."

    # Install httpd
    yum install httpd -y

    # Setup /opt/apache directory
    rm -rf ${APACHE_HOME}
    mkdir -p ${APACHE_HOME}

    # Move/Link web root and configs to /opt/apache for custom management
    cp -r /etc/httpd/* ${APACHE_HOME}/
    
    # Create a symlink so systemd still works but you can manage from /opt/apache
    ln -sf /etc/httpd/conf/httpd.conf ${APACHE_HOME}/httpd.conf

    # Ensure it starts on port 80 (default)
    sed -i 's/Listen 80/Listen 80/g' /etc/httpd/conf/httpd.conf

    systemctl enable httpd
    systemctl restart httpd

    echo "Apache HTTPD installed and set up in ${APACHE_HOME}"
else
    echo "Skipping Apache HTTPD installation..."
fi

# ... [Tomcat Installation block remains same] ...

# ------------------------------------------------
# Final Status
# ------------------------------------------------

echo ""
echo "============= FINAL STATUS ============="
echo "EC2 Public IP: ${PUBLIC_IP}"

# ... [Previous Status checks for Java, Maven, Docker, Jenkins, Sonar remain] ...

# ------------------------------------------------
# Apache HTTPD Status (New Section)
# ------------------------------------------------

echo ""
if systemctl is-active --quiet httpd; then
    echo "Apache HTTPD started successfully"
    echo "Apache URL: http://${PUBLIC_IP}:80"
    echo "Config location: ${APACHE_HOME}/httpd.conf"
else
    echo "Apache HTTPD failed to start"
fi

# ... [Tomcat Status and Port Status remain same] ...

echo ""
echo "============= PORT STATUS ============="
ss -tulnp | grep -E '80|8080|9000|9090'
