#!/bin/bash

# Docker CE & Compose 插件安装脚本 (支持 Debian/Ubuntu/Armbian)
# 
# 修复说明: 增加了自动识别 OS (Ubuntu/Debian) 的逻辑，解决了 Ubuntu 系统报错 404 的问题
# 去掉了 sudo，直接用 bash 运行
# curl -fsSL https://raw.githubusercontent.com/YonQua/YonQua.github.io/main/install_docker.sh | bash
# 日期: 2026-03-18

set -e

# ============================================
# 1. 权限检查
# ============================================
if [ "$(id -u)" -ne 0 ]; then
   echo "错误: 该脚本必须以 root 权限运行"
   echo "请使用: sudo $0"
   exit 1
fi

REAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}
if [ "$REAL_USER" = "root" ]; then
    REAL_USER=""
fi

# ============================================
# 2. 系统信息
# ============================================
echo "=== Docker CE 与 Compose 插件安装 ==="
echo "系统: $(lsb_release -ds)"
echo "架构: $(dpkg --print-architecture)"
[ -n "$REAL_USER" ] && echo "用户: $REAL_USER"
echo ""

ARCH=$(dpkg --print-architecture)

# ============================================
# 3. 安装依赖
# ============================================
echo ""
echo "[1/8] 更新软件包索引..."
apt-get update

echo "[2/8] 安装依赖包..."
apt-get install -y ca-certificates curl gnupg lsb-release

# ============================================
# 4. 卸载旧版本
# ============================================
echo "[3/8] 卸载旧版 Docker..."
apt-get remove -y docker docker-engine docker.io containerd runc docker-compose 2>/dev/null || true
# 注意：不强制 autoremove，以免误删其他依赖，如有需要手动执行

# ============================================
# 5. 添加 Docker 官方源 (关键修复步骤)
# ============================================
echo "[4/8] 添加 Docker GPG 密钥..."
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/docker.gpg
# 根据发行版自动选择 GPG URL
DISTRO_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

# 如果是 LinuxMint 等基于 Ubuntu 的发行版，强制识别为 ubuntu
if [[ "$DISTRO_ID" == "linuxmint" ]]; then DISTRO_ID="ubuntu"; fi

curl -fsSL https://download.docker.com/linux/$DISTRO_ID/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "[5/8] 设置 Docker 仓库 (自动识别模式)..."
# 使用识别到的 DISTRO_ID (debian 或 ubuntu)
echo "识别到的发行版类型: $DISTRO_ID"

cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO_ID $(lsb_release -cs) stable
EOF

# ============================================
# 6. 安装 Docker
# ============================================
echo "[6/8] 安装 Docker CE 与插件..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin

# ============================================
# 7. 启动服务
# ============================================
echo "[7/8] 启动 Docker 服务..."
systemctl start docker
systemctl enable docker

# ============================================
# 8. 配置用户组
# ============================================
if [ -n "$REAL_USER" ]; then
    echo "[8/8] 将用户 $REAL_USER 添加到 docker 组..."
    groupadd docker 2>/dev/null || true
    usermod -aG docker "$REAL_USER"
else
    echo "[8/8] 跳过用户组配置（未检测到普通用户）"
fi

# ============================================
# 9. 验证安装
# ============================================
echo ""
echo "=== 验证安装 ==="
docker -v
docker compose version

# ============================================
# 10. 完成提示
# ============================================
echo ""
echo "=== 安装完成 ==="
echo "官方文档: https://docs.docker.com/"
echo ""

if [ -n "$REAL_USER" ]; then
    echo "⚠ 重要: 请注销重新登录，或执行 'newgrp docker' 使权限生效。"
fi
echo ""
