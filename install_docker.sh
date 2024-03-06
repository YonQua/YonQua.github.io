#!/bin/bash

# 确保脚本以root权限执行
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 更新软件包索引
echo "更新软件包索引..."
sudo apt-get update

# 安装`apt`依赖包，这些包允许`apt`通过HTTPS使用仓库
echo "安装apt依赖包..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker的官方GPG密钥
echo "添加Docker的官方GPG密钥..."
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


# 设置稳定版的仓库
echo "设置Docker的稳定版仓库..."
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 再次更新软件包索引
echo "更新软件包索引..."
sudo apt-get update

# 安装Docker Engine
echo "安装Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 安装Docker Compose
echo "安装Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 在Debian中使用不带sudo的Docker
# 尝试创建docker组，忽略如果已存在的错误
echo "创建docker用户组..."
sudo groupadd docker 2>/dev/null

# 将当前用户添加到docker用户组
echo "将当前用户添加到docker用户组..."
sudo usermod -aG docker $USER

# 安装完成后的验证
echo "安装完成，正在验证安装结果..."
sudo docker --version
docker-compose --version

# 提示用户重新登录或重启
echo "请注销然后重新登录，或者重启你的系统以应用用户组更改，以无需sudo使用Docker和Docker Compose。"


# 使用说明：
# 使用git clone命令克隆仓库
# git clone https://github.com/YonQua/YonQua.github.io.git
# curl -o install_docker.sh https://raw.githubusercontent.com/YonQua/YonQua.github.io/main/install_docker.sh
# chmod +x install_docker.sh
# sudo ./install_docker.sh
