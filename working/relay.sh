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
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/xray/xray"
GEOIP_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/xray/geoip.dat"
GEOSITE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/xray/geosite.dat"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/xray/xray.service"

# 定义目标路径 
PROGRAM_PATH="/usr/local/bin/xray"
GEOIP_PATH="/usr/local/bin/geoip.dat"
GEOSITE_PATH="/usr/local/bin/geosite.dat"
SERVICE_PATH="/etc/systemd/system/xray.service"

# 检查 xray 是否已经存在 
if [ -f "$PROGRAM_PATH" ]; then 
  echo -e "${YELLOW}  xray 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 xray...${NC}"
  curl -L -o xray "$PROGRAM_URL"
  sudo mv xray "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN} xray 下载并配置完成！${NC}"
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
if [ -f "$GEOSITE_PATH" ]; then 
  echo -e "${YELLOW}  geosite.dat 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 geosite.dat...${NC}"
  curl -L -o geosite.dat "$GEOSITE_URL"
  sudo mv geosite.dat "$GEOSITE_PATH"
  sudo chmod +x "$GEOSITE_PATH"
  echo -e "${GREEN} geosite.dat 下载并配置完成！${NC}"
fi 

# 检查 xray.service 是否已经存在 
if [ -f "$SERVICE_PATH" ]; then 
  echo -e "${YELLOW}  xray.service 已存在，跳过下载。${NC}"
else 
  # 下载服务文件 
  echo -e "${BLUE} 正在下载 xray.service...${NC}"
  curl -L -o xray.service "$SERVICE_URL"
  sudo mv xray.service "$SERVICE_PATH"
  echo -e "${GREEN} xray.service 下载并配置完成！${NC}"
fi 

# 检查 /etc/xray 目录是否存在 
if [ ! -d "/etc/xray" ]; then 
  echo -e "${BLUE} 目录 /etc/xray 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/xray
  if [ $? -eq 0 ]; then 
    echo -e "${GREEN} 目录创建成功。${NC}"
  else 
    echo -e "${RED} 目录创建失败，请检查权限。${NC}"
    exit 1 
  fi 
else 
  echo -e "${YELLOW} 目录 /etc/xray 已存在。${NC}"
fi 

# 检查 xray.json 是否存在，存在则删除 
if [ -f "/etc/xray/xray.json" ]; then 
  echo -e "${YELLOW}  xray.json 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/xray/xray.json
fi 

# 提示用户输入IP地址 
read -p "请输入需要转发的IP地址: " ip_address 

# 验证输入是否为有效的IP地址 
if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then 
  echo -e "${GREEN} 输入的IP地址有效：$ip_address${NC}"
else 
  echo -e "${RED}  输入的不是有效的IP地址，请重新运行脚本并输入正确的IP。${NC}"
  exit 1 
fi 

# 创建 xray.json 并写入内容 
echo -e "${BLUE} 正在创建 xray.json 文件...${NC}"
cat <<EOF | sudo tee /etc/xray/xray.json
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
        "listen": "127.0.0.1",
        "port": 62789,
        "protocol": "dokodemo-door",
        "settings": {
          "address": "127.0.0.1"
        },
        "streamSettings": null,
        "tag": "api",
        "sniffing": null
      },
      {
        "listen": null,
        "port": 1116,
        "protocol": "dokodemo-door",
        "settings": {
          "address": "$ip_address",
          "port": 1116,
          "network": "tcp,udp"
        },
        "streamSettings": {
          "network": "tcp",
          "security": "none",
          "tcpSettings": {
            "header": {
              "type": "none"
            }
          }
        },
        "tag": "inbound-1116",
        "sniffing": {}
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
  echo -e "${GREEN} xray.json 文件创建成功${NC}"
else 
  echo -e "${RED} 文件创建失败，请检查权限。${NC}"
  exit 1 
fi 

# 重新加载 systemd 管理器配置 
echo -e "${BLUE} 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload 

# 启动服务 
echo -e " 正在启动 xray.service...${NC}"
sudo systemctl restart xray.service 

# 设置服务开机自启动 
sudo systemctl enable xray.service 
echo -e "${GREEN} xray.service 设置为开机自启动。${NC}"

# 检查服务状态 
echo -e "${BLUE} 正在检查服务状态...${NC}"
sudo systemctl status xray.service 

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
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/client/client"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/client/client.service"

# 定义目标路径 
PROGRAM_PATH="/usr/local/bin/client"
SERVICE_PATH="/etc/systemd/system/client.service"

# 检查 client 是否已经存在 
if [ -f "$PROGRAM_PATH" ]; then 
  echo -e "${YELLOW}  client 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 client...${NC}"
  curl -L -o client "$PROGRAM_URL"
  sudo mv client "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN} client 下载并配置完成！${NC}"
fi 

# 检查 client.service 是否已经存在 
if [ -f "$SERVICE_PATH" ]; then 
  echo -e "${YELLOW}  client.service 已存在，跳过下载。${NC}"
else 
  # 下载服务文件 
  echo -e "${BLUE} 正在下载 client.service...${NC}"
  curl -L -o client.service "$SERVICE_URL"
  sudo mv client.service "$SERVICE_PATH"
  echo -e "${GREEN} client.service 下载并配置完成！${NC}"
fi 

# 检查 /etc/client 目录是否存在 
if [ ! -d "/etc/client" ]; then 
  echo -e "${BLUE} 目录 /etc/client 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/client
  if [ $? -eq 0 ]; then 
    echo -e "${GREEN} 目录创建成功。${NC}"
  else 
    echo -e "${RED} 目录创建失败，请检查权限。${NC}"
    exit 1 
  fi 
else 
  echo -e "${YELLOW}  目录 /etc/client 已存在。${NC}"
fi 

# 检查 client.conf 是否存在，存在则删除 
if [ -f "/etc/client/client.conf" ]; then 
  echo -e "${YELLOW}  client.conf 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/client/client.conf
fi 

# 创建 client.conf 并写入内容 
echo -e "${BLUE} 正在创建 client.conf 文件...${NC}"
cat <<EOF | sudo tee /etc/client/client.conf
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
  echo -e "${GREEN} client.conf 文件创建成功${NC}"
else 
  echo -e "${RED} 文件创建失败，请检查权限。${NC}"
  exit 1 
fi 

# 重新加载 systemd 管理器配置 
echo -e "${BLUE} 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload 

# 启动服务 
echo -e " 正在启动 client.service...${NC}"
sudo systemctl restart client.service 

# 设置服务开机自启动 
sudo systemctl enable client.service 
echo -e "${GREEN} client.service 设置为开机自启动。${NC}"

# 检查服务状态 
echo -e "${BLUE} 正在检查服务状态...${NC}"
sudo systemctl status client.service 

# 提示完成 
echo -e "${GREEN} 下载和配置完成！${NC}"

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
