#!/bin/bash

# 设置 PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
rootness() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}必须使用 root 账号运行!${NC}" 1>&2
        exit 1
    fi
}

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

# 获取系统信息
get_os_info() {
    IP=$(ip addr | grep inet | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    [ -z ${IP} ] && IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
}

# 生成随机字符串
rand() {
    index=0
    str=""
    for i in {a..z} {A..Z} {0..9}; do arr[index]=${i}; index=$((index + 1)); done
    for i in {1..10}; do str="$str${arr[$RANDOM % $index]}"; done
    echo ${str}
}

# L2TP 预安装
preinstall_l2tp() {
    iprange="192.168.18"
    mypsk="hm123456"
    echo -e "${GREEN}###########################${NC}"
    echo -e "${GREEN}公网 IP: ${IP}${NC}"
    echo -e "${GREEN}L2TP 网关: ${iprange}.1${NC}"
    echo -e "${GREEN}拨入客户端可用 IP 范围: ${iprange}.2-${iprange}.254${NC}"
    echo -e "${GREEN}PSK 预共享密钥: ${mypsk}${NC}"
    echo -e "${GREEN}###########################${NC}"
}

# 安装 L2TP
install_l2tp() {
    mknod /dev/random c 1 9
    apt update
    apt -y install ppp strongswan xl2tpd iptables
    config_install
}

# 配置安装
config_install() {
    cat > /etc/ipsec.conf <<EOF
version 2.0

config setup
    protostack=netkey
    nhelpers=0
    uniqueids=no
    interfaces=%defaultroute
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!${iprange}.0/24

conn l2tp-psk
    rightsubnet=vhost:%priv
    also=l2tp-psk-nonat

conn l2tp-psk-nonat
    authby=secret
    pfs=no
    auto=add
    keyingtries=0
    rekey=no
    ikelifetime=24h
    keylife=8h
    type=transport
    left=%defaultroute
    leftid=${IP}
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=30
    dpdtimeout=120
    dpdaction=clear
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
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
ppp debug = no
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

    cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 223.5.5.5
auth
hide-password
idle 999999
mtu 1400
mru 1400
debug

connect-delay 1000
EOF
# proxyarp 是用于启用代理 ARP 的选项
# noccp 禁用了 PPP 压缩协议，这在某些情况下是必要的，但在高带宽环境中可能导致更高的传输延迟。
# nodefaultroute 此参数防止 L2TP 客户端修改默认路由，如果您希望所有流量都通过 VPN，可以移除这行配置。
    rm -f /etc/ppp/chap-secrets
    cat > /etc/ppp/chap-secrets <<EOF
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
EOF
}

# 最后步骤
finally() {
    echo -e "${YELLOW}验证安装${NC}"
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
    echo -e "${YELLOW}开始安装${NC}"
    rootness
    tunavailable
    disable_selinux
    get_os_info
    preinstall_l2tp
    install_l2tp
    finally
}

# 开始执行
l2tp

iptables -F
iptables -P INPUT ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE
ip -4 a | grep inet | grep -v "127.0.0.1" | awk '{print $2,$NF}' | sed "s/\/[0-9]\{1,2\}//g" > system_ip.txt

start_num=2
rm -f ./account.txt
psk=$(cat /etc/ipsec.secrets | awk '{print $5}' | sed 's/"//g')
ip=$(cat /etc/ipsec.conf | grep leftid | awk -F "=" '{print $2}')


nic_ip=$(echo $line | awk '{print $1}')
# echo -e "${GREEN}创建第 $((start_num - 1)) 个${NC}"
echo "user1     l2tpd     hm123456     192.168.18.3" >> /etc/ppp/chap-secrets
echo "user2     l2tpd     hm123456     192.168.18.4" >> /etc/ppp/chap-secrets
echo "user3     l2tpd     hm123456     192.168.18.5" >> /etc/ppp/chap-secrets
echo "user4     l2tpd     hm123456     192.168.18.6" >> /etc/ppp/chap-secrets
echo "user5     l2tpd     hm123456     192.168.18.7" >> /etc/ppp/chap-secrets
echo "user6     l2tpd     hm123456     192.168.18.8" >> /etc/ppp/chap-secrets
echo "user7     l2tpd     hm123456     192.168.18.9" >> /etc/ppp/chap-secrets
echo "user8     l2tpd     hm123456     192.168.18.10" >> /etc/ppp/chap-secrets
echo "user9     l2tpd     hm123456     192.168.18.11" >> /etc/ppp/chap-secrets
echo "user10    l2tpd     hm123456     192.168.18.12" >> /etc/ppp/chap-secrets
echo "user11    l2tpd     hm123456     192.168.18.13" >> /etc/ppp/chap-secrets
echo "user12    l2tpd     hm123456     192.168.18.14" >> /etc/ppp/chap-secrets
echo "user13    l2tpd     hm123456     192.168.18.15" >> /etc/ppp/chap-secrets
echo "root      l2tpd     hm123456     192.168.18.100" >> /etc/ppp/chap-secrets
systemctl restart xl2tpd
systemctl restart ipsec

preinstall_l2tp
cat /etc/ppp/chap-secrets
