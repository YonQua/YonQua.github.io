

#!/bin/bash

sudo apt update
sudo apt install dante-server

sudo rm /etc/danted.conf



# 创建并编辑 /etc/danted.conf
sudo nano /etc/danted.conf <<EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# The listening network interface or address.
internal: 0.0.0.0 port=1080

# The proxying network interface or address.
external: eth0

# socks-rules determine what is proxied through the external interface.
socksmethod: username

# client-rules determine who can connect to the internal interface.
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0/0
}
EOF



sudo useradd -r -s /bin/false harlan
echo -e "leishao\nleishao" | sudo passwd harlan



sudo systemctl restart danted.service


systemctl status danted.service
