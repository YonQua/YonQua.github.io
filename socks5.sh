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
    
    # Check if Xray is already installed
    if [ -x "$(command -v xrayL)" ]; then
        echo "Xray is already installed. Skipping installation."
    else
        # Install required packages
        apt-get install unzip -y || yum install unzip -y

        # Download and install Xray
        wget https://github.com/XTLS/Xray-core/releases/download/v1.8.3/Xray-linux-64.zip
        unzip Xray-linux-64.zip
        mv xray /usr/local/bin/xrayL
        chmod +x /usr/local/bin/xrayL

        # Create systemd service
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

        # Reload and start the service
        systemctl daemon-reload
        systemctl enable xrayL.service
        systemctl start xrayL.service

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

    # Loop through each IP address
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

        # Append configuration to the file
        echo -e "$config_content" >> /etc/xrayL/config.toml
    }

    # Restart Xray service
    systemctl restart xrayL.service

    # Display configuration details
    echo ""
    echo "Generated $config_type configuration:"
    echo "Starting port: $START_PORT"
    echo "Ending port: $((START_PORT + ${#IP_ADDRESSES[@]} - 1))"
    echo "SOCKS username: $SOCKS_USERNAME"
    echo "SOCKS password: $SOCKS_PASSWORD"
    echo ""
}

# Main function
main() {
    # Check if Xray is installed and install if needed
    [ -x "$(command -v xrayL)" ] || install_xray
    
    # Configure Xray
    config_xray
}

# Execute the main function
main
