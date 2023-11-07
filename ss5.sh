#!/bin/bash

# Function to install and start the SOCKS5 service
install_and_start_socks() {
    # Create Systemd service file for sockd
    cat <<EOF > /etc/systemd/system/sockd.service
    [Unit]
    Description=Socks Service
    After=network.target nss-lookup.target

    [Service]
    User=nobody
    CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
    AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
    NoNewPrivileges=true
    ExecStart=/usr/local/bin/socks run -config /etc/socks/config.yaml
    Restart=on-failure
    RestartPreventExitStatus=23
    LimitNPROC=10000
    LimitNOFILE=1000000

    [Install]
    WantedBy=multi-user.target
    EOF

    # Configure and start the SOCKS5 service
    config_install() {
        port="1080"  # Replace with the desired port number
        user="your_username"  # Replace with your chosen username
        passwd="your_password"  # Replace with your chosen password

        # Create configuration file for socks
        mkdir -p /etc/socks
        cat <<CONFIG_EOF > /etc/socks/config.yaml
        {
            "log": {
                "loglevel": "warning"
            },
            "routing": {
                "domainStrategy": "AsIs"
            },
            "inbounds": [
                {
                    "listen": "0.0.0.0",
                    "port": "$port",
                    "protocol": "socks",
                    "settings": {
                        "auth": "password",
                        "accounts": [
                            {
                                "user": "$user",
                                "pass": "$passwd"
                            }
                        ],
                        "udp": true
                    },
                    "streamSettings": {
                        "network": "tcp"
                    }
                }
            ],
            "outbounds": [
                {
                    "protocol": "freedom",
                    "tag": "direct"
                },
                {
                    "protocol": "blackhole",
                    "tag": "block"
                }
            ]
        }
        CONFIG_EOF

        # Start the sockd.service
        systemctl daemon-reload
        systemctl enable sockd.service &> /dev/null
        systemctl start sockd.service
    }

    # Call the function to configure and start SOCKS5 service
    config_install
}

# Run the function to install and start SOCKS5
install_and_start_socks
