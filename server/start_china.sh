#!/bin/bash

# 定义颜色函数，用于醒目的输出提示
info() {
    echo -e "\e[32m$1\e[0m"
}
error() {
    echo -e "\e[31m$1\e[0m"
}

# 设置 DEBIAN_FRONTEND 为 noninteractive，避免任何交互提示
export DEBIAN_FRONTEND=noninteractive

info "======== 停止 systemd-resolved 服务 ========"

# 停止 systemd-resolved 服务
systemctl stop systemd-resolved.service
systemctl disable systemd-resolved.service

# 修改DNS设置
info "======== 修改DNS设置 ========"

# 备份原有的resolv.conf文件
if [ -f /etc/resolv.conf ]; then
    cp /etc/resolv.conf /etc/resolv.conf.bak
    info "已备份 /etc/resolv.conf 到 /etc/resolv.conf.bak"
fi

# 写入新的DNS服务器
cat > /etc/resolv.conf <<EOF
nameserver 223.5.5.5
nameserver 119.29.29.29
nameserver 2400:3200::1
nameserver 2400:3200:baba::1
EOF

# 防止文件被还原
chattr +i /etc/resolv.conf
info "/etc/resolv.conf 已更新并锁定"

# 判断系统防火墙并关闭
info "======== 判断防火墙并关闭 ========"

# 防火墙列表
firewalls=("ufw" "firewalld")
firewall_found=false

for firewall in "${firewalls[@]}"; do
    if command -v "$firewall" &> /dev/null; then
        firewall_found=true
        info "检测到 $firewall 防火墙，正在关闭..."
        if [ "$firewall" == "ufw" ]; then
            ufw --force disable && info "ufw防火墙已关闭"
        elif [ "$firewall" == "firewalld" ]; then
            systemctl stop firewalld && systemctl disable firewalld && info "firewalld防火墙已关闭"
        fi
    fi
done

if ! $firewall_found; then
    info "未检测到已启用的防火墙服务"
fi

# 更新系统包信息
info "======== 更新包信息 ========"
if apt-get update -y; then
    info "系统包信息已更新"
else
    error "系统包信息更新失败"
    exit 1
fi

# 更新包列表并安装软件
info "======== 更新包列表并安装软件 ========"
if apt-get install -y net-tools vim iperf3 speedtest-cli unzip; then
    info "软件安装完成"
else
    error "软件安装失败"
    exit 1
fi

info "======== 脚本执行完毕 ========"
