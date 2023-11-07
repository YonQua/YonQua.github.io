#!/bin/bash

# Update package lists
sudo apt update  

# Install dante-server package
sudo apt install dante-server

# Remove default config file
sudo rm /etc/danted.conf

# Create and edit new config file
sudo cat <<EOF | sudo tee /etc/danted.conf

# Log to syslog
logoutput: syslog

# Run as root user
user.privileged: root  

# Run unprivileged child processes as nobody user
user.unprivileged: nobody

# Listen on all interfaces on port 1080  
internal: 0.0.0.0 port=1080

# Use eth0 for outgoing connections
external: eth0

# Use username/password auth for SOCKS connections
socksmethod: username 

# Allow all clients without authentication
clientmethod: none

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
}

socks pass {
  from: 0.0.0.0/0 to: 0.0.0/0 
}

EOF

# Create unprivileged user account
sudo useradd -r -s /bin/false leishao

# Set password for leishao user 
echo -e "leishao\nleishao" | sudo passwd leishao

# Restart danted service
sudo systemctl restart danted.service

# Check status  
sudo systemctl status danted.service
