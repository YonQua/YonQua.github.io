#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# 更新系统源
apt update
apt-get install -y unzip

# 切换到脚本目录 
cd "$(dirname "$0")"

# 检查参数
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <username> <password> <socks_port>"
  exit 1
fi

# 定义变量
USERNAME=$1
PASSWORD=$2
SOCKS_PORT=$3

# 其他变量...

# 安装Xray
if ! command -v xray &> /dev/null; then
  # 下载解压
  wget https://github.com/XTLS/Xray-core/releases/download/v1.8.3/Xray-linux-64.zip
  unzip Xray-linux-64.zip
  cp xray /usr/local/bin/xray

  # 添加systemd服务
  cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
After=network.target
[Service]
ExecStart=/usr/local/bin/xray run -c /etc/xray/config.json
Restart=on-failure
User=root
[Install]  
WantedBy=multi-user.target
EOF

  mkdir -p /etc/xray
  sudo systemctl enable xray.service
  sudo systemctl start xray.service
else
  echo "Xray already installed."
fi

# 生成配置文件
cat > /etc/xray/config.json <<EOF
{
  "outbounds": [
    {
      "tag": "WARP",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "$WARP_SECRET_KEY",
        "address": ["172.16.0.2/32", "fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128"],
        "peers": [
          {
            "publicKey": "$WARP_PUBLIC_KEY",
            "endpoint": "$WARP_ENDPOINT"
          }
        ]
      }
    },
    {
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "0.0.0.0",
            "port": $SOCKS_PORT,
            "method": "none",
            "password": "$PASSWORD"
          }
        ]
      },
      "tag": "socks"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "domain": ["domain:openai.com", "domain:ai.com"],
        "outboundTag": "WARP"
      },
      {
        "type": "field",
        "outboundTag": "socks"
      }
    ]
  }
}
EOF

# 启动Xray
if ! pgrep -x "xray" > /dev/null; then
  sudo systemctl start xray.service
  echo "Xray started." 
fi

echo "Xray SOCKS proxy running on port $SOCKS_PORT"
