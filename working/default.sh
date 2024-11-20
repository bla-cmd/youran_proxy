#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # 没有颜色

    echo "                                                    ______                   _                     
   /\                                              (_____ \                 (_)               _    
  /  \   _ _ _   ____   ___   ___   ____    ____    _____) )  ____   ___     _   ____   ____ | |_  
 / /\ \ | | | | / _  ) /___) / _ \ |    \  / _  )  |  ____/  / ___) / _ \   | | / _  ) / ___)|  _) 
| |__| || | | |( (/ / |___ || |_| || | | |( (/ /   | |      | |    | |_| |  | |( (/ / ( (___ | |__ 
|______| \____| \____)(___/  \___/ |_|_|_| \____)  |_|      |_|     \___/  _| | \____) \____) \___)
                                                                          (__/                     "

# 定义下载链接 
PROGRAM_URL="https://github.moeyy.xyz/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/youran"
GEOIP_URL="https://github.moeyy.xyz/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/geoip.dat"
GEOSITE_URL="https://github.moeyy.xyz/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/geosite.dat"
SERVICE_URL="https://github.moeyy.xyz/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/youran.service"

# 定义目标路径 
PROGRAM_PATH="/usr/local/bin/youran"
GEOIP_PATH="/usr/local/bin/geoip.dat"
GEOSITE_PATH="/usr/local/bin/geosite.dat"
SERVICE_PATH="/etc/systemd/system/youran.service"

#!/bin/bash

# 检查 xray 是否已安装
if command -v xray &> /dev/null; then
    echo "检测到 xray 已安装。"

    # 停止并禁用 xray 服务
    echo "停止并禁用 xray 服务..."
    systemctl stop xray
    systemctl disable xray

    # 删除 xray 可执行文件和服务文件
    echo "删除 xray 可执行文件和服务文件..."
    rm -f /usr/local/bin/xray
    rm -f /etc/systemd/system/xray.service

    # 删除配置文件夹
    if [ -d /etc/xray ]; then
        echo "删除 /etc/xray 文件夹..."
        rm -rf /etc/xray
    fi

    if [ -d /usr/local/etc/xray ]; then
        echo "删除 /usr/local/etc/xray 文件夹..."
        rm -rf /usr/local/etc/xray
    fi

    # 重新加载 systemd
    echo "重新加载 systemd 配置..."
    systemctl daemon-reload

    # 检查 xray 是否还在运行，如果在则强制终止
    if pgrep -x "xray" > /dev/null; then
        echo "xray 仍在运行，执行 killall..."
        killall xray
    else
        echo "xray 已停止运行。"
    fi
else
    echo "xray 未安装，无需操作。"
fi


# 检查 youran 是否已经存在 
if [ -f "$PROGRAM_PATH" ]; then 
  echo -e "${YELLOW}  youran 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 youran...${NC}"
  curl -L -o youran "$PROGRAM_URL"
  sudo mv youran "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN} youran 下载并配置完成！${NC}"
fi 

# 检查 geoip.dat 是否已经存在 
if [ -f "$GEOIP_PATH" ]; then 
  echo -e "${YELLOW}  geoip.dat 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 geoip.dat...${NC}"
  curl -L -o geoip.dat "$GEOIP_URL"
  sudo mv geoip.dat "$GEOIP_PATH"
  sudo chmod +x "$GEOIP_PATH"
  echo -e "${GREEN} geoip.dat 下载并配置完成！${NC}"
fi 

# 检查 geosite.dat 是否已经存在 
if [ -f "$SERVICE_PATH" ]; then
  echo -e "${YELLOW}youran.service 已存在，删除旧文件...${NC}"
  sudo rm -f "$SERVICE_PATH"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 geosite.dat...${NC}"
  curl -L -o geosite.dat "$GEOSITE_URL"
  sudo mv geosite.dat "$GEOSITE_PATH"
  sudo chmod +x "$GEOSITE_PATH"
  echo -e "${GREEN} geosite.dat 下载并配置完成！${NC}"
fi 

# 检查 youran.service 是否已经存在 
if [ -f "$SERVICE_PATH" ]; then 
  echo -e "${YELLOW}  youran.service 已存在，跳过下载。${NC}"
else 
  # 下载服务文件 
  echo -e "${BLUE} 正在下载 youran.service...${NC}"
  curl -L -o youran.service "$SERVICE_URL"
  sudo mv youran.service "$SERVICE_PATH"
  echo -e "${GREEN} youran.service 下载并配置完成！${NC}"
fi 

# 检查 /etc/youran 目录是否存在 
if [ ! -d "/etc/youran" ]; then 
  echo -e "${BLUE} 目录 /etc/youran 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/youran
  if [ $? -eq 0 ]; then 
    echo -e "${GREEN} 目录创建成功。${NC}"
  else 
    echo -e "${RED} 目录创建失败，请检查权限。${NC}"
    exit 1 
  fi 
else 
  echo -e "${YELLOW} 目录 /etc/youran 已存在。${NC}"
fi 

# 检查 youran.json 是否存在，存在则删除 
if [ -f "/etc/youran/youran.json" ]; then 
  echo -e "${YELLOW}  youran.json 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/youran/youran.json
fi 


# 创建 youran.json 并写入内容 
echo -e "${BLUE} 正在创建 youran.json 文件...${NC}"
cat <<EOF | sudo tee /etc/youran/youran.json
{
  "log": null,
  "routing": {
    "rules": [
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked",
        "type": "field"
      },
      {
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ],
        "type": "field"
      }
    ]
  },
  "dns": null,
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 1116,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-256-gcm",
        "password": "112233",
        "network": "tcp,udp"
      },
      "streamSettings": null,
      "tag": "inbound-ss",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "transport": null,
  "policy": {
    "system": {
      "statsInboundDownlink": true,
      "statsInboundUplink": true
    }
  },
  "api": {
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ],
    "tag": "api"
  },
  "stats": {},
  "reverse": null,
  "fakeDns": null
}
EOF

if [ $? -eq 0 ]; then 
  echo -e "${GREEN} youran.json 文件创建成功${NC}"
else 
  echo -e "${RED} 文件创建失败，请检查权限。${NC}"
  exit 1 
fi 

# 重新加载 systemd 管理器配置 
echo -e "${BLUE} 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload 

# 启动服务 
echo -e " 正在启动 youran.service...${NC}"
sudo systemctl restart youran.service 

# 设置服务开机自启动 
sudo systemctl enable youran.service 
echo -e "${GREEN} youran.service 设置为开机自启动。${NC}"


# 提示完成 
echo -e "${GREEN} 下载和配置完成！${NC}"

#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # 没有颜色

    echo "                                                    ______                   _                     
   /\                                              (_____ \                 (_)               _    
  /  \   _ _ _   ____   ___   ___   ____    ____    _____) )  ____   ___     _   ____   ____ | |_  
 / /\ \ | | | | / _  ) /___) / _ \ |    \  / _  )  |  ____/  / ___) / _ \   | | / _  ) / ___)|  _) 
| |__| || | | |( (/ / |___ || |_| || | | |( (/ /   | |      | |    | |_| |  | |( (/ / ( (___ | |__ 
|______| \____| \____)(___/  \___/ |_|_|_| \____)  |_|      |_|     \___/  _| | \____) \____) \___)
                                                                          (__/                     "

# 定义下载链接  
PROGRAM_URL="https://github.moeyy.xyz/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server"
SERVICE_URL="https://github.moeyy.xyz/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server.service"

# 定义目标路径  
PROGRAM_PATH="/usr/local/bin/server"
SERVICE_PATH="/etc/systemd/system/server.service"

# 检查 server 是否已经存在
if [ -f "$PROGRAM_PATH" ]; then 
  echo -e "${YELLOW}  server 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 server...${NC}"
  curl -L -o server "$PROGRAM_URL"
  sudo mv server "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN} server 下载并配置完成！${NC}"
fi 

# 检查 server.service 是否已经存在
if [ -f "$SERVICE_PATH" ];then 
  echo -e "${YELLOW}  server.service 已存在，跳过下载。${NC}"
else 
  # 下载服务文件 
  echo -e "${BLUE} 正在下载 server.service...${NC}"
  curl -L -o server.service "$SERVICE_URL"
  sudo mv server.service "$SERVICE_PATH"
  echo -e "${GREEN} server.service 下载并配置完成！${NC}"
fi 

# 检查 /etc/server 目录是否存在
if [ ! -d "/etc/server" ]; then 
  echo -e "${BLUE} 目录 /etc/server 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/server
  if [ $? -eq 0 ]; then 
    echo -e "${GREEN} 目录创建成功。${NC}"
  else 
    echo -e "${RED} 目录创建失败，请检查权限。${NC}"
    exit 1 
  fi 
else 
  echo -e "${YELLOW}  目录 /etc/server 已存在。${NC}"
fi 

# 检查 server.conf 是否存在，存在则删除旧文件
if [ -f "/etc/server/server.conf" ]; then 
  echo -e "${YELLOW}  server.conf 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/server/server.conf
fi 

# 尝试自动获取公网IP地址
ip_address=$(curl -s http://ifconfig.me)  
if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then  
  echo -e "${GREEN} 获取到的公网IP地址为：$ip_address${NC}" 
else  
  echo -e "${RED} 无法自动获取公网IP地址，请手动输入。${NC}"
 
  # 提示用户输入IP地址 
  read -p "请输入需要转发的IP地址: " ip_address 
 
  # 验证输入是否为有效的IP地址 
  if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then  
    echo -e "${GREEN} 输入的IP地址有效：$ip_address${NC}" 
  else  
    echo -e "${RED} 输入的不是有效的IP地址，请重新运行脚本并输入正确的IP。${NC}" 
    exit 1  
  fi  
fi
 

# 创建 server.conf 并写入内容  
echo -e "${BLUE} 正在创建 server.conf 文件...${NC}"
cat <<EOF | sudo tee /etc/server/server.conf
[{ 
    "listenAddr": ":4500", 
    "forwardAddr": "$ip_address:4500", 
    "timeout": 60 
}, { 
    "listenAddr": ":1701", 
    "forwardAddr": "$ip_address:1701", 
    "timeout": 60 
}, { 
    "listenAddr": ":500", 
    "forwardAddr": "$ip_address:500", 
    "timeout": 60 
}] 
EOF

if [ $? -eq 0 ]; then 
  echo -e "${GREEN} server.conf 文件创建成功${NC}"
else 
  echo -e "${RED} 文件创建失败，请检查权限。${NC}"
  exit 1 
fi 

# 重新加载 systemd 管理器配置  
echo -e "${BLUE} 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload 

# 启动服务  
echo -e "${BLUE} 正在启动 server.service...${NC}"
sudo systemctl restart server.service 

# 设置服务开机自启动  
sudo systemctl enable server.service 
echo -e "${GREEN} server.service 设置为开机自启动。${NC}"

# 提示完成  
echo -e "${GREEN} 下载和配置完成！${NC}"


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
    dpddelay=6000 # Dead Peer Detection (DPD) 的检测间隔时间，设置为 6000 秒，每 6000 秒发送一次检测包。
    dpdtimeout=6000 # 如果 6000 秒内没有收到远程对端的 DPD 响应，认为对端失联。
    dpdaction=restart # 在检测到对端失联后，自动重启连接，确保连接可以自动恢复。
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
ms-dns 223.5.5.5
ms-dns 8.8.8.8
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

echo "vpnuser1     l2tpd     hm123456     192.168.43.3" >> /etc/ppp/chap-secrets
echo "root         l2tpd     hm123456     192.168.43.253" >> /etc/ppp/chap-secrets

cat /etc/ppp/chap-secrets
# 重新启动服务
systemctl restart xl2tpd
systemctl restart ipsec

