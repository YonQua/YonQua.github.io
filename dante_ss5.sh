#!/bin/bash

# 定义默认参数
SOCKSPORT=2445 
socksUser="leishao"
socksPass="leishao"

# 安装 SOCKS5 代理服务器
apt-get update
apt-get install wget nano dante-server netcat -y &> /dev/null | echo '[*] Installing SOCKS5 Server...'
cat <<'EOF'> /etc/danted.conf
logoutput: /var/log/socks.log
internal: 0.0.0.0 port = SOCKSPORT
external: SOCKSINET
socksmethod: SOCKSAUTH
user.privileged: root
user.notprivileged: nobody

client pass {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: error connect disconnect
 }
 
client block {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: connect error
 }
 
socks pass {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: error connect disconnect
 }
 
socks block {
 from: 0.0.0.0/0 to: 0.0.0.0/0
 log: connect error
 }
EOF
sed -i "s/SOCKSPORT/$SOCKSPORT/g" /etc/danted.conf  
sed -i "s/SOCKSAUTH/username/g" /etc/danted.conf

useradd -m -s /bin/false $socksUser
echo -e "$socksPass\n$socksPass\n" | passwd $socksUser

systemctl restart danted
systemctl enable danted

# 显示信息
echo "SOCKS5 代理已安装"
echo "端口:$SOCKSPORT"
echo "用户名:$socksUser"
echo "密码:$socksPass"
