#!/bin/bash

set -e

echo "Updating package list and installing OpenLDAP and dependencies..."
sudo apt update
sudo apt install -y slapd ldap-utils git apache2 php php-ldap

echo "Reconfiguring slapd (interactive)..."
# This will prompt you for domain name, admin password, etc.
sudo dpkg-reconfigure slapd

echo "Setting LDAP DB_CONFIG for performance..."
sudo bash -c 'cat <<EOF > /var/lib/ldap/DB_CONFIG
set_cachesize 0 2097152 0
set_lg_bsize 2097152
EOF'
sudo chown openldap:openldap /var/lib/ldap/DB_CONFIG

echo "Restarting and enabling slapd service..."
sudo systemctl restart slapd
sudo systemctl enable slapd

echo "Cloning LDAP configuration repository..."
cd /opt
if [ ! -d openldap ]; then
  sudo git clone https://github.com/linuxautomations/openldap.git
fi
cd /opt/openldap

echo "Applying LDAP configurations..."

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif

# The following schema files are usually pre-loaded with slapd.
# Uncomment only if needed and if you get errors about missing schemas.
# sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
# sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
# sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f chdomain.ldif

echo "Adding base domain entries — you will be prompted for LDAP admin password..."
sudo ldapadd -x -D cn=admin,dc=linuxautomations,dc=com -W -f basedomain.ldif

echo "Setting up LDAP Account Manager (LAM)..."
sudo mkdir -p /var/www/html/lam
sudo tar -xvzf /opt/openldap/lam.tgz -C /var/www/html/lam --strip-components=1

echo "Restarting and enabling Apache server..."
sudo systemctl restart apache2
sudo systemctl enable apache2

echo "✅ Installation complete! Access LAM at: http://<your-server-ip>/lam"
