!/bin/bash

# Define variables
PROXY_PORT=24451
PROXY_USER=leishao
PROXY_PASS=leishao

# Update package lists
sudo apt update

# Install dante-server package
sudo apt install dante-server -y

# Remove default configuration file
sudo rm -f /etc/danted.conf

# Get the main network interface name
interface_name=$(ip -o -4 route show to default | awk '{print $5}')

# Configure SOCKS5
echo "Configuring SOCKS5 ..."

# Use a here-document to create the new danted.conf file
sudo bash -c "cat > /etc/danted.conf <<EOF
# logoutput: /var/log/danted.log
logoutput: stderr
internal: 0.0.0.0 port = $PROXY_PORT
external: $interface_name
clientmethod: none
socksmethod: username none #rfc931
user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody
client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}
socks pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}
socks pass {
  from: ::/0 to: ::/0
  log: error connect disconnect
}
EOF"


# Create an unprivileged user account
sudo useradd -r -s /sbin/nologin $PROXY_USER

# Set password for the proxy user
echo -e "$PROXY_PASS\n$PROXY_PASS" | sudo passwd $PROXY_USER > /dev/null 2>&1


sudo service danted stop

sudo service danted start

# Restart danted service
# sudo systemctl restart danted

# Check service status
sudo systemctl status danted.service
