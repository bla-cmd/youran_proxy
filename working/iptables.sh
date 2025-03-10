#!/bin/bash

# 检查操作系统类型
if [ -f /etc/debian_version ]; then
    OS="Debian/Ubuntu"
    INSTALL_PERSISTENT="iptables-persistent"
elif [ -f /etc/redhat-release ]; then
    OS="CentOS/RHEL"
    INSTALL_PERSISTENT=""
else
    echo "不支持的操作系统！"
    exit 1
fi

# 检查 IPv6 是否已禁用
if sysctl -n net.ipv6.conf.all.disable_ipv6 | grep -q '1'; then
    echo -e "${GREEN}IPv6 已禁用，无需再次设置${NC}"
else
    # 禁用 IPv6 并将其写入 /etc/sysctl.conf
    if ! grep -q '^net.ipv6.conf.all.disable_ipv6=1' /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
    fi
    if ! grep -q '^net.ipv6.conf.default.disable_ipv6=1' /etc/sysctl.conf; then
        echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
    fi
    if ! grep -q '^net.ipv6.conf.lo.disable_ipv6=1' /etc/sysctl.conf; then
        echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
    fi

    # 立即应用禁用 IPv6 设置
    if sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && sysctl -w net.ipv6.conf.lo.disable_ipv6=1 && sysctl -p; then
        echo -e "${GREEN}IPv6 已成功禁用并应用${NC}"
    else
        echo -e "${RED}禁用 IPv6 失败${NC}"
    fi
fi




# 获取 eth0 的 IP 地址并将其设置为变量
SERVER_IP=$(ip -o -f inet addr show eth0 | awk '/scope global/ {print $4}')

# 获取 m.parso.org 的 IP 地址
PARSO_IP=$(getent hosts m.parso.org | awk '{ print $1 }')

# 清理 iptables nat 规则
iptables -t nat -F
iptables -t nat -X

# 创建 GOST 链
iptables -t nat -N GOST

# 忽略局域网流量，请根据实际网络环境进行调整
iptables -t nat -A GOST -d $SERVER_IP -j RETURN

# 忽略 m.parso.org 的流量
if [ -n "$PARSO_IP" ]; then
    iptables -t nat -A GOST -d $PARSO_IP -j RETURN
    echo "已放行 m.parso.org 的 IP：$PARSO_IP"
else
    echo "无法解析 m.parso.org 的 IP，未添加放行规则"
fi

# 忽略 SSH 流量 (22端口)
iptables -t nat -A GOST -p tcp --dport 22 -j RETURN

# 忽略出口流量
iptables -t nat -A GOST -p tcp -m mark --mark 100 -j RETURN

# 忽略 DNS 流量 (udp 协议的 53 端口)
iptables -t nat -A GOST -p udp --dport 53 -j RETURN

# 重定向 TCP 流量到 12345 端口
iptables -t nat -A GOST -p tcp -j REDIRECT --to-ports 12345

# 拦截局域网流量
iptables -t nat -A PREROUTING -p tcp -j GOST

# 拦截本机流量
iptables -t nat -A OUTPUT -p tcp -j GOST

# 输出提示
echo "iptables 规则已设置完毕，忽略局域网流量的 IP 为：$SERVER_IP"

# 保存 iptables 规则
echo "正在保存 iptables 规则..."

if [[ "$OS" == "Debian/Ubuntu" ]]; then
    # 在 Debian/Ubuntu 上安装 iptables-persistent 并保存规则
    echo "操作系统检测为 $OS，使用 iptables-persistent 保存规则"
    sudo apt update
    sudo apt install -y iptables-persistent
    sudo netfilter-persistent save
    echo "iptables 规则已保存"
    
elif [[ "$OS" == "CentOS/RHEL" ]]; then
    # 在 CentOS/RHEL 上保存 iptables 规则
    echo "操作系统检测为 $OS，使用 iptables 服务保存规则"
    sudo service iptables save
    echo "iptables 规则已保存"

    # 确保 iptables 在系统启动时自动加载
    sudo systemctl enable iptables
    sudo systemctl start iptables
fi

echo "iptables 规则设置并保存完毕。"





#!/bin/bash

# 设置 PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 检查是否为 root 用户
rootness() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}必须使用 root 账号运行!${NC}" 1>&2
        exit 1
    fi
}


# 检查IP转发是否已开启 
if sysctl -n net.ipv4.ip_forward | grep -q '1'; then 
    echo -e "${GREEN}IP转发已开启，无需添加设置${NC}" 
else 
    # 添加IP转发设置到 /etc/sysctl.conf 
    if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then 
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf 
    fi 
 
    # 立即应用设置 
    if sysctl -w net.ipv4.ip_forward=1 && sysctl -p; then 
        echo -e "${GREEN}IP转发已成功开启${NC}" 
    else 
        echo -e "${RED}IP转发开启失败${NC}" 
    fi 
fi 
 
# 检查并启用Google BBR 
if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then 
    echo -e "${GREEN}BBR 已启用，无需再次设置${NC}" 
else 
    # 启用 BBR 
    if ! grep -q '^net.core.default_qdisc=fq' /etc/sysctl.conf; then 
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
    fi 
    if ! grep -q '^net.ipv4.tcp_congestion_control=bbr' /etc/sysctl.conf; then 
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf 
    fi 
 
    # 立即应用 BBR 设置 
    if sysctl -w net.core.default_qdisc=fq && sysctl -w net.ipv4.tcp_congestion_control=bbr && sysctl -p; then 
        echo -e "${GREEN}BBR 已成功启用${NC}" 
    else 
        echo -e "${RED}BBR 启用失败${NC}" 
    fi 
fi  


# 检查 TUN/TAP 设备
tunavailable() {
    if [[ ! -e /dev/net/tun ]]; then
        echo -e "${RED}TUN/TAP 设备不可用!${NC}" 1>&2
        exit 1
    fi
}

# 禁用 SELinux
disable_selinux() {
    if command -v selinuxenabled > /dev/null 2>&1 && selinuxenabled; then
        echo -e "${YELLOW}SELinux 已启用，正在禁用中...${NC}"
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    fi
}


# L2TP 预安装信息
preinstall_l2tp() {
    iprange="192.168.43"
    mypsk="hm123456"
    echo "                                                    ______                   _                     
   /\                                              (_____ \                 (_)               _    
  /  \   _ _ _   ____   ___   ___   ____    ____    _____) )  ____   ___     _   ____   ____ | |_  
 / /\ \ | | | | / _  ) /___) / _ \ |    \  / _  )  |  ____/  / ___) / _ \   | | / _  ) / ___)|  _) 
| |__| || | | |( (/ / |___ || |_| || | | |( (/ /   | |      | |    | |_| |  | |( (/ / ( (___ | |__ 
|______| \____| \____)(___/  \___/ |_|_|_| \____)  |_|      |_|     \___/  _| | \____) \____) \___)
                                                                          (__/                     "
}

# 检查操作系统类型并执行相应的安装命令
install_l2tp() {
    if [ -f /etc/debian_version ]; then
        echo "检测到 Debian/Ubuntu 系统，正在安装 L2TP 及相关依赖..."
        apt update
        apt -y install ppp strongswan xl2tpd iptables
        config_install
    elif [ -f /etc/redhat-release ]; then
        echo "检测到 CentOS/RHEL 系统，正在安装 L2TP 及相关依赖..."
        yum -y install epel-*
        yum -y install ppp libreswan xl2tpd iptables-services iptables
        systemctl enable iptables
        systemctl start iptables
        config_install
    else
        echo "不支持的操作系统！请手动安装相关依赖。"
        exit 1
    fi
}

# 配置 L2TP/IPsec
config_install() {
    cat > /etc/ipsec.conf <<EOF
version 2.0


config setup
    protostack=netkey
    nhelpers=8 # 定义使用 8 个额外的 helper 线程来处理加密和解密操作。
    uniqueids=yes # 允许同一个用户（IP地址）发起多个并发的连接。如果设置为 "yes"，旧连接将会在新的连接建立时被终止。
    interfaces=%defaultroute
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!${iprange}.0/24
    
conn l2tp-psk # 定义一个 L2TP-PSK（预共享密钥）连接配置。
    rightsubnet=vhost:%priv # 远程子网设置为虚拟主机模式，%priv 表示远程对端使用私有地址。
    also=l2tp-psk-nonat # 引用另一个连接块 "l2tp-psk-nonat" 中的设置，以减少重复代码。
    
conn l2tp-psk-nonat # 另一个连接块，定义 L2TP-PSK 连接的具体设置。
    authby=secret # 使用预共享密钥 (PSK) 进行身份验证。
    pfs=no # 禁用完全前向保密 (PFS)，减少加密复杂度和资源开销，提升性能。
    auto=add # 该连接会在 IPsec 服务启动时自动加载并尝试建立连接。
    keyingtries=3 # 在连接失败时重试密钥协商的次数，设置为 3 次重试。
    rekey=yes # 启用密钥重新协商。当密钥有效期到达时，将自动重新协商新的密钥。
    ikelifetime=72h # IKE（Internet Key Exchange）密钥的生存时间，设置为 24 小时，减少频繁的重新协商。
    keylife=72h # IPSec 安全关联 (SA) 的密钥生存时间，设置为 24 小时。
    type=transport # 使用传输模式 (transport mode)，这种模式只加密数据的有效负载，不加密整个 IP 数据包头。
    left=%defaultroute # 本地 IP 地址使用默认路由接口上的地址。
    leftid=${IP} # 本地身份标识符，设置为本地的 IP 地址。
    leftprotoport=17/%any # 定义本地使用的协议和端口号，17 表示 UDP 协议，1701 是 L2TP 使用的端口。
    right=%any # 远程对端的 IP 地址，%any 表示可以接受任何远程地址的连接。
    rightprotoport=17/%any # 远程对端的协议和端口号，17 表示 UDP 协议，%any 表示可以接受任何远程端口号。
    dpddelay=60 # Dead Peer Detection (DPD) 的检测间隔时间，设置为 60 秒，每 60 秒发送一次检测包。
    dpdtimeout=60 # 如果 60 秒内没有收到远程对端的 DPD 响应，认为对端失联。
    dpdaction=clear # 在检测到对端失联后，自动重启连接，确保连接可以自动恢复。
EOF

    cat > /etc/ipsec.secrets <<EOF
%any %any : PSK "${mypsk}"
EOF

    cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701
[lns default]
ip range = ${iprange}.2-${iprange}.254
local ip = ${iprange}.1
require chap = no
refuse pap = no
require authentication = no
name = l2tpd
ppp debug = no 
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

    cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 119.29.29.29
auth
noccp
mtu 1400
mru 1400
nodefaultroute
connect-delay 0
EOF

    rm -f /etc/ppp/chap-secrets
    cat > /etc/ppp/chap-secrets <<EOF
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
EOF
}


# 最终安装步骤
finally() {
    ipsec verify
    ufw disable
    systemctl enable xl2tpd
    systemctl enable ipsec
    systemctl restart xl2tpd
    systemctl restart ipsec
    echo -e "${GREEN}安装完成${NC}"
}

# 主程序
l2tp() {
    rootness
    tunavailable
    disable_selinux
    preinstall_l2tp
    install_l2tp
    finally
}

# 开始执行
l2tp

# 防火墙和 NAT 配置
iptables -F
iptables -P INPUT ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE

echo "vpnuser1     l2tpd     hm123456     192.168.43.3" >> /etc/ppp/chap-secrets
echo "root         l2tpd     hm123456     192.168.43.253" >> /etc/ppp/chap-secrets

cat /etc/ppp/chap-secrets
# 重新启动服务
systemctl restart xl2tpd
systemctl restart ipsec
