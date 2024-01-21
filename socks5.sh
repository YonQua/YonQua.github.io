#!/bin/bash

DEFAULT_START_PORT=20000                         # Default starting port
DEFAULT_SOCKS_USERNAME="userb"                   # Default SOCKS username
DEFAULT_SOCKS_PASSWORD="passwordb"               # Default SOCKS password

IP_ADDRESSES=($(hostname -I))

install_xray() {
    echo "Installing Xray..."
    apt-get update
    apt-get install unzip -y

    if [ -x "$(command -v xrayL)" ]; then
        echo "Xray is already installed, skipping installation."
    else
        wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
        unzip Xray-linux-64.zip
        mv xray /usr/local/bin/xrayL
        chmod +x /usr/local/bin/xrayL

        cat <<EOF >/etc/systemd/system/xray.service
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xrayL -c /etc/xray/config.toml
Restart=on-failure
User=nobody
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable xray.service
        systemctl start xray.service
        echo "Xray installation completed."
    fi
}

config_xray() {
    config_content=""
    config_type="socks"
    
    read -p "Starting port (default $DEFAULT_START_PORT): " START_PORT
    START_PORT=${START_PORT:-$DEFAULT_START_PORT}

    read -p "SOCKS username (default $DEFAULT_SOCKS_USERNAME): " SOCKS_USERNAME
    SOCKS_USERNAME=${SOCKS_USERNAME:-$DEFAULT_SOCKS_USERNAME}

    read -p "SOCKS password (default $DEFAULT_SOCKS_PASSWORD): " SOCKS_PASSWORD
    SOCKS_PASSWORD=${SOCKS_PASSWORD:-$DEFAULT_SOCKS_PASSWORD}

    for ((i = 0; i < ${#IP_ADDRESSES[@]}; i++)); do
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
    done

    echo -e "$config_content" >> /etc/xray/config.toml
    systemctl restart xray.service
    systemctl --no-pager status xray.service
    echo ""
    echo "$config_type configuration generated successfully"
    echo "Starting port: $START_PORT"
    echo "Ending port: $((START_PORT + ${#IP_ADDRESSES[@]} - 1))"
    echo "SOCKS username: $SOCKS_USERNAME"
    echo "SOCKS password: $SOCKS_PASSWORD"
    echo ""
}

main() {
    [ -x "$(command -v xrayL)" ] || install_xray
    config_xray
}

main


## bash <(curl -fsSLk https://raw.githubusercontent.com/YonQua/YonQua.github.io/main/socks5.sh) socks
