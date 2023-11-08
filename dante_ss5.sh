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
port = $PROXY_PORT 
method = username
user.privileged = root
user.notprivileged = nobody
client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}
socks pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}
EOF

# 创建服务脚本
cat > /etc/systemd/system/danted.service <<EOF
[Unit]
Description=Dante SOCKS5 proxy server
After=network.target
[Service]
ExecStart=/usr/sbin/danted --foreground
[Install]  
WantedBy=multi-user.target
EOF

# 添加用户和密码
useradd -m -s /bin/false -p $(openssl passwd -1 $PROXY_PASS) $PROXY_USER

# 启动服务
systemctl enable danted
systemctl restart danted

# 打开端口
iptables -I INPUT -p tcp --dport $PROXY_PORT -j ACCEPT

echo "SOCKS5 安装完成"
echo "端口:$PROXY_PORT"
echo "用户名:$PROXY_USER"
echo "密码: $PROXY_PASS"
