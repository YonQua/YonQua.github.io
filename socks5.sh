DEFAULT_START_PORT=20000                         #默认起始端口
DEFAULT_SOCKS_USERNAME="userb"                   #默认socks账号
DEFAULT_SOCKS_PASSWORD="passwordb"               #默认socks密码

IP_ADDRESSES=($(hostname -I))

install_xray() {
    echo "安装 Xray..."
    apt-get install unzip -y || yum install unzip -y

    if [ -x "$(command -v xrayL)" ]; then
        echo "Xray 已经安装，跳过安装步骤."
    else
        wget https://github.com/XTLS/Xray-core/releases/download/v1.8.3/Xray-linux-64.zip
        unzip Xray-linux-64.zip
        mv xray /usr/local/bin/xrayL
        chmod +x /usr/local/bin/xrayL

        cat <<EOF >/etc/systemd/system/xrayL.service
[Unit]
Description=XrayL Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xrayL -c /etc/xrayL/config.toml
Restart=on-failure
User=nobody
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable xrayL.service
        systemctl start xrayL.service
        echo "Xray 安装完成."
    fi
}


config_xray() {
    config_type="socks"
    read -p "起始端口 (默认 $DEFAULT_START_PORT): " START_PORT
    START_PORT=${START_PORT:-$DEFAULT_START_PORT}

    read -p "SOCKS 账号 (默认 $DEFAULT_SOCKS_USERNAME): " SOCKS_USERNAME
    SOCKS_USERNAME=${SOCKS_USERNAME:-$DEFAULT_SOCKS_USERNAME}

    read -p "SOCKS 密码 (默认 $DEFAULT_SOCKS_PASSWORD): " SOCKS_PASSWORD
    SOCKS_PASSWORD=${SOCKS_PASSWORD:-$DEFAULT_SOCKS_PASSWORD}

    for ((i = 0; i < ${#IP_ADDRESSES[@]}; i++)); do
        config_content=""
        config_content+="[[inbounds]]\n"
        config_content+="port = $((START_PORT + i))\n"
        config_content+="protocol = \"$config_type\"\n"
        config_content+="tag = \"tag_$((i + 1))\"\n"
        config_content+="[inbounds.settings]\n"
        config_content+="auth = \"password\"\n"
        config_content+="udp = true\n"
        config_content+="ip = \"0.0.0.0\"\n"  # Use IPv4 address
        config_content+="[[inbounds.settings.accounts]]\n"
        config_content+="user = \"$SOCKS_USERNAME\"\n"
        config_content+="pass = \"$SOCKS_PASSWORD\"\n"
        config_content+="[[outbounds]]\n"
        config_content+="sendThrough = \"0.0.0.0\"\n"  # Use IPv4 address
        config_content+="protocol = \"freedom\"\n"
        config_content+="tag = \"tag_$((i + 1))\"\n\n"
        config_content+="[[routing.rules]]\n"
        config_content+="type = \"field\"\n"
        config_content+="inboundTag = \"tag_$((i + 1))\"\n"
        config_content+="outboundTag = \"tag_$((i + 1))\"\n\n\n"

        echo -e "$config_content" >> /etc/xrayL/config.toml
    }

    systemctl restart xrayL.service
    systemctl --no-pager status xrayL.service
    echo ""
    echo "生成 $config_type 配置完成"
    echo "起始端口:$START_PORT"
    echo "结束端口:$(($START_PORT + ${#IP_ADDRESSES[@]} - 1))"
    echo "socks账号:$SOCKS_USERNAME"
    echo "socks密码:$SOCKS_PASSWORD"
    echo ""
}


main() {
    [ -x "$(command -v xrayL)" ] || install_xray
    config_xray
}

main
