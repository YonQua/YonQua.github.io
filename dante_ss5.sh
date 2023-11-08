#!/bin/bash

# SOCKS5 安装脚本

# 定义变量
PROXY_PORT=2445
PROXY_USER=leishao
PROXY_PASS=leishao

# 检查是否已安装
if [ -f /etc/danted.conf ]; then
  echo "SOCKS5 已安装,退出"
  exit
fi

# 安装
echo "安装 SOCKS5 ..." 
apt-get update
apt-get install -y dante-server danted || { echo "安装失败"; exit 1; }

# 配置
echo "配置 SOCKS5 ..."

cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log
internal: eth0 port = $PROXY_PORT
external: eth0

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

# 创建服务脚本
cat > /etc/systemd/system/sockd.service <<EOF
[Unit]
Description=Dante SOCKS5 proxy server
After=network.target

[Service]
ExecStart=/usr/sbin/sockd -D

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl daemon-reload
systemctl enable sockd
systemctl start sockd

# 打开端口
iptables -I INPUT -p tcp --dport $PROXY_PORT -j ACCEPT

echo "SOCKS5 安装完成"
echo "端口:$PROXY_PORT"
echo "用户名:$PROXY_USER"
echo "密码: $PROXY_PASS"
