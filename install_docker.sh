#!/bin/bash

# Docker CE & Compose 插件安装脚本 (Debian/Armbian)
# 
# 使用方式:
#   方式1 (推荐): curl -fsSL https://raw.githubusercontent.com/YonQua/YonQua.github.io/main/install_docker.sh | sudo bash
#   方式2: wget https://raw.githubusercontent.com/YonQua/YonQua.github.io/main/install_docker.sh && sudo bash install_docker.sh
#   方式3: git clone https://github.com/YonQua/YonQua.github.io.git && cd YonQua.github.io && sudo bash install_docker.sh
# 
# 日期: 2025-11-07

set -e

# ============================================
# 1. 权限检查
# ============================================
if [ "$(id -u)" -ne 0 ]; then
   echo "错误: 该脚本必须以 root 权限运行"
   echo "请使用: sudo $0"
   exit 1
fi

# 获取真实用户（即使通过 sudo 运行）
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

# 检测架构兼容性
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64|arm64|armhf)
        echo "✓ 架构 $ARCH 受官方支持"
        ;;
    *)
        echo "⚠ 警告: 架构 $ARCH 可能不被官方支持"
        read -p "是否继续? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        ;;
esac

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
apt-get autoremove -y

# ============================================
# 5. 添加 Docker 官方源
# ============================================
echo "[4/8] 添加 Docker GPG 密钥..."
mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "[5/8] 设置 Docker 仓库..."
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable
EOF

# ============================================
# 6. 安装 Docker
# ============================================
echo "[6/8] 安装 Docker CE 与插件..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
echo ""
echo "常用命令:"
echo "  docker ps                # 查看容器"
echo "  docker images            # 查看镜像"
echo "  docker compose up -d     # 启动项目（后台）"
echo "  docker compose down      # 停止项目"
echo "  docker system prune      # 清理未使用资源"
echo ""
echo "官方文档: https://docs.docker.com/"
echo ""
echo "=========================================="
echo "一键安装命令 (可分享给他人):"
echo "curl -fsSL https://raw.githubusercontent.com/YonQua/YonQua.github.io/main/install_docker.sh | sudo bash"
echo "=========================================="

# 权限提醒
if [ -n "$REAL_USER" ]; then
    echo ""
    echo "⚠ 重要: 请注销重新登录，或执行以下命令使 docker 组权限生效:"
    echo "   newgrp docker"
fi

echo ""
