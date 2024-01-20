#!/bin/bash

# Default variables
DEFAULT_START_PORT=20000
DEFAULT_SOCKS_USERNAME="userb" 
DEFAULT_SOCKS_PASSWORD="passwordb"

# Get all available IP addresses
IP_ADDRESSES=($(hostname -I))

# Install Xray function
install_xray() {

  echo "Installing Xray..."

  # 检查Xray是否已安装
  if [ -x "$(command -v xray)" ]; then
    echo "Xray is already installed. Skipping installation."
  else 
    # 安装所需组件
    apt-get install unzip -y || yum install unzip -y

    # 下载和安装Xray
    wget https://github.com/XTLS/Xray-core/releases/download/v1.8.3/Xray-linux-64.zip
    unzip Xray-linux-64.zip
    mv xray /usr/local/bin/xray
    chmod +x /usr/local/bin/xray

    # 创建系统服务 
    cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service  
After=network.target

[Service]
ExecStart=/usr/local/bin/xray -c /etc/xray/config.json
Restart=on-failure
User=nobody
RestartSec=3

[Install]
WantedBy=multi-user.target  
EOF

    # 重新加载并启动服务
    systemctl daemon-reload
    systemctl enable xray.service
    systemctl start xray.service  

    echo "Xray installed successfully."
  
  fi

}

# Configure Xray function  
config_xray() {

  config_type="socks"

  read -p "Starting port (default $DEFAULT_START_PORT): " START_PORT
  START_PORT=${START_PORT:-$DEFAULT_START_PORT}

  read -p "SOCKS username (default $DEFAULT_SOCKS_USERNAME): " SOCKS_USERNAME
  SOCKS_USERNAME=${SOCKS_USERNAME:-$DEFAULT_SOCKS_USERNAME}

  read -p "SOCKS password (default $DEFAULT_SOCKS_PASSWORD): " SOCKS_PASSWORD
  SOCKS_PASSWORD=${SOCKS_PASSWORD:-$DEFAULT_SOCKS_PASSWORD}

  # 循环每个IP地址
  for ((i = 0; i < ${#IP_ADDRESSES[@]}; i++)); do

    config_content=""
    
    config_content+="[[inbounds]]\n"  
    config_content+="port = $((START_PORT + i))\n"
    config_content+="protocol = \"$config_type\"\n"
    config_content+="tag = \"tag_$((i + 1))\"\n"

    config_content+="[inbounds.settings]\n"
    config_content+="auth = \"password\"\n" 
    config_content+="udp = true\n"
    config_content+="ip = \"${IP_ADDRESSES[i]}\"\n"

    config_content+="[[inbounds.settings.accounts]]\n"
    config_content+="user = \"$SOCKS_USERNAME\"\n"
    config_content+="pass = \"$SOCKS_PASSWORD\"\n"

    config_content+="[[outbounds]]\n"
    config_content+="sendThrough = \"${IP_ADDRESSES[i]}\"\n" 
    config_content+="protocol = \"freedom\"\n"
    config_content+="tag = \"tag_$((i + 1))\"\n\n"

    config_content+="[[routing.rules]]\n"
    config_content+="type = \"field\"\n"
    config_content+="inboundTag = \"tag_$((i + 1))\"\n" 
    config_content+="outboundTag = \"tag_$((i + 1))\"\n\n\n"

    # 添加到配置文件
    echo -e "$config_content" >> /etc/xray/config.json

  done

}

# 重新启动Xray服务
systemctl restart xray 

# 显示配置信息
echo ""  
echo "Generated $config_type configuration:"
echo "Starting port: $START_PORT"
echo "Ending port: $((START_PORT + ${#IP_ADDRESSES[@]} - 1))" 
echo "SOCKS username: $SOCKS_USERNAME"
echo "SOCKS password: $SOCKS_PASSWORD"
echo ""

# 主函数
main() {

  # 检查并安装Xray
  [ -x "$(command -v xray)" ] || install_xray
  
  # 生成配置
  config_xray 

}

main
