#!/bin/bash

set -e

echo "Installing OpenLDAP and dependencies..."
sudo apt update
sudo apt install slapd ldap-utils git apache2 php php-ldap -y

echo "Reconfiguring slapd (interactive)..."
sudo dpkg-reconfigure slapd

echo "Setting LDAP DB_CONFIG..."
sudo bash -c 'cat <<EOF > /var/lib/ldap/DB_CONFIG
set_cachesize 0 2097152 0
set_lg_bsize 2097152
EOF'
sudo chown openldap:openldap /var/lib/ldap/DB_CONFIG

sudo systemctl restart slapd
sudo systemctl enable slapd

echo "Cloning configuration repository..."
cd /opt
if [ ! -d openldap ]; then
  sudo git clone https://github.com/linuxautomations/openldap.git
fi
cd /opt/openldap

echo "Applying LDAP configurations..."
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f chdomain.ldif

echo "Adding base domain entries (enter LDAP admin password)..."
sudo ldapadd -x -D cn=admin,dc=linuxautomations,dc=com -W -f basedomain.ldif

echo "Setting up LAM (LDAP Account Manager)..."
sudo mkdir -p /var/www/html/lam
sudo tar -xvzf /opt/openldap/lam.tgz -C /var/www/html/lam --strip-components=1

sudo systemctl restart apache2
sudo systemctl enable apache2

echo "✅ Installation complete. Access LAM at: http://<your-server-ip>/lam"
