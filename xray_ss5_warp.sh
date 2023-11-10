#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# 更新系统源
apt update
apt install -y unzip
# 切换到脚本所在目录
cd "$(dirname "$0")"

# 检查是否提供了必要的参数
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <username> <password> <socks_port>"
    exit 1
fi

# 提取参数
USERNAME=$1
PASSWORD=$2
SOCKS_PORT=$3
WARP_SECRET_KEY="Bk2DlifX7QjNZXGiWSFUJYLORv2U/FHNhHbpbKoy9xk="
WARP_PUBLIC_KEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
WARP_ENDPOINT="engage.cloudflareclient.com:2408"
CONFIG_FILE="/etc/xray/config.json"

# 下载并解压 Xray
if ! command -v xray &> /dev/null; then
    wget https://github.com/XTLS/Xray-core/releases/download/latest/xray-linux-64.zip
    unzip xray-linux-64.zip -d /usr/local/bin
    rm xray-linux-64.zip
else
    echo "Xray is already installed."
fi

# 创建 Xray 配置文件目录
mkdir -p "$(dirname "$CONFIG_FILE")"

# 创建 Xray 配置文件
cat <<EOF > "$CONFIG_FILE"
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

# 启动 Xray
if pgrep -x "xray" > /dev/null; then
    echo "Xray is already running."
else
    xray -c "$CONFIG_FILE" > /dev/null 2>&1 &
    echo "Xray has been started."
fi

# 显示提示信息
echo "Xray SOCKS Proxy is running on port $SOCKS_PORT with username $USERNAME and password $PASSWORD."
