#!/bin/bash

# 默认变量
DEFAULT_SOCKS_PORT=1080  
DEFAULT_SOCKS_USERNAME="user"
DEFAULT_SOCKS_PASSWORD="password"

# 安装Xray
install_xray() {
  echo "安装Xray..."
  
  if [ -x "$(command -v xray)" ]; then
    echo "Xray已安装,跳过安装步骤。"
  else
    # 下载并安装
    wget https://github.com/XTLS/Xray-core/releases/download/v1.8.7/Xray-linux-64.zip
    unzip Xray-linux-64.zip
    mv xray /usr/local/bin/xray
    chmod +x /usr/local/bin/xray
    
    # 生成系统服务
    cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
User=nobody
RestartSec=3

[Install]  
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl enable xray
    systemctl start xray
  
  fi

  echo "Xray 安装完成。"
}

# 生成Xray配置  
generate_config() {
  port=$1
  username=$2
  password=$3
  
  cat >> /etc/xray/config.json <<EOF
{
  "inbounds": [
    {
      "port": $port,
      "protocol": "socks",
      "settings": {
        "udp": true,  
        "auth": "password",
        "accounts": [
          {"user": "$username", "pass": "$password"} 
        ]
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]  
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
}

# 主函数
main() {

  # 安装Xray
  install_xray

  # 生成配置
  IP_LIST=($(hostname -I))

  port=$DEFAULT_SOCKS_PORT

  for ip in ${IP_LIST[@]}; do
    generate_config $port $DEFAULT_SOCKS_USERNAME $DEFAULT_SOCKS_PASSWORD
    port=$((port+1))
  done

  # 重启Xray
  systemctl restart xray  

  echo "Xray 配置完成。"
  echo "端口范围:$DEFAULT_SOCKS_PORT - $((port-1))" 
  echo "账号:$DEFAULT_SOCKS_USERNAME"
  echo "密码:$DEFAULT_SOCKS_PASSWORD"
}

main
