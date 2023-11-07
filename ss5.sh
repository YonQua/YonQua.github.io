#!/bin/bash

# Update package lists
sudo apt update  

# Install dante-server package
sudo apt install dante-server

# Remove default config file
sudo rm /etc/danted.conf

# Create and edit new config file
sudo bash -c 'cat <<EOF > /etc/danted.conf
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# The listening network interface or address.
internal: 0.0.0.0 port=1080

# The proxying network interface or address.
external: enX0

# socks-rules determine what is proxied through the external interface.
socksmethod: username

# client-rules determine who can connect to the internal interface.
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOF'

# Create unprivileged user account
sudo useradd -r -s /bin/false leishao

# Set password for leishao user 
echo -e "leishao\nleishao" | sudo passwd leishao

# Restart danted service
sudo systemctl restart danted.service

# Check status  
sudo systemctl status danted.service
