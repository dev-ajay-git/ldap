#!/bin/bash

# Update package list and install required packages
sudo apt update
sudo apt install -y libnss-ldap libpam-ldap ldap-utils nslcd

# Ask for LDAP server IP
read -p 'Enter LDAP Server IP Address: ' ip

# Configure LDAP client
sudo auth-client-config -t nss -p lac_ldap

# Modify /etc/ldap.conf or /etc/nslcd.conf to point to your LDAP server IP
sudo sed -i "s|^uri .*|uri ldap://$ip/|" /etc/ldap/ldap.conf

# Configure NSS to use LDAP
sudo pam-auth-update --enable mkhomedir

echo "LDAP client setup complete."
