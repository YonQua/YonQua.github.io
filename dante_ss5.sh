#!/bin/bash

# 定义变量
PROXY_PORT=2445
PROXY_USER=leishao
PROXY_PASS=leishao

# 更新软件包列表
sudo apt update  

# 安装 dante-server 软件包
sudo apt install dante-server

# 删除默认配置文件
sudo rm /etc/danted.conf

# 获取主要网络接口名称
interface_name=$(ip -o -4 route show to default | awk '{print $5}')

# 配置 SOCKS5
echo "配置 SOCKS5 ..."

cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log
internal: $interface_name port = $PROXY_PORT
external: $interface_name

method: username
user.privileged: root
user.notprivileged: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}

socks pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}
EOF

# 添加用户和密码
useradd -s /usr/sbin/nologin $PROXY_USER
echo "$PROXY_USER:$PROXY_PASS" | chpasswd


# Restart danted service
sudo systemctl restart danted.service

# Check status  
sudo systemctl status danted.service
