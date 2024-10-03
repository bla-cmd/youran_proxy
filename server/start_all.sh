#!/bin/bash


# 定义颜色函数，用于醒目的输出提示
info() {
    echo -e "\e[32m$1\e[0m"
}
error() {
    echo -e "\e[31m$1\e[0m"
}

# 0. 修改DNS设置
info "======== 修改DNS设置 ========"

# 备份原有的resolv.conf文件
cp /etc/resolv.conf /etc/resolv.conf.bak

# 写入新的DNS服务器
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
EOF

# 防止 resolv.conf 被自动覆盖（可选）
chattr +i /etc/resolv.conf
info "DNS服务器已修改并锁定"

# 0. 关闭 systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved

# 1. 开启IP转发

info "======== 检查IP转发状态 ========"

# 检查IP转发是否已开启
if sysctl net.ipv4.ip_forward | grep -q '1'; then
    info "IP转发已开启，无需添加设置"
else
    # 添加IP转发设置到 /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf

    if sysctl -w net.ipv4.ip_forward=1 && sysctl -p; then
        info "IP转发已开启"
    else
        error "IP转发开启失败"
    fi
fi


# 2. 判断系统防火墙并关闭
info "======== 判断防火墙并关闭 ========"

# 防火墙列表
firewalls=("ufw" "firewalld")
firewall_found=false

for firewall in "${firewalls[@]}"; do
    if command -v "$firewall" &> /dev/null; then
        firewall_found=true
        info "检测到 $firewall 防火墙，正在关闭..."
        if [ "$firewall" == "ufw" ]; then
            ufw disable && info "ufw防火墙已关闭"
        elif [ "$firewall" == "firewalld" ]; then
            systemctl stop firewalld && systemctl disable firewalld && info "firewalld防火墙已关闭"
        fi
    fi
done

if ! $firewall_found; then
    info "未检测到已启用的防火墙服务"
fi

# 3. 更新系统包信息
info "======== 更新包信息 ========"
if apt update -y; then
    info "系统包信息已更新"
else
    error "系统包信息更新失败"
fi

# 4. 安装vim和net-tools
info "======== 安装vim和net-tools ========"
if apt install -y vim net-tools; then
    info "vim 和 net-tools 已安装"
else
    error "vim 和 net-tools 安装失败"
fi


info "======== 脚本执行完毕 ========"
