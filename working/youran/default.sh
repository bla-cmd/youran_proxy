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
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/youran"
GEOIP_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/geoip.dat"
GEOSITE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/geosite.dat"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/youran/youran.service"

# 定义目标路径 
PROGRAM_PATH="/usr/local/bin/youran"
GEOIP_PATH="/usr/local/bin/geoip.dat"
GEOSITE_PATH="/usr/local/bin/geosite.dat"
SERVICE_PATH="/etc/systemd/system/youran.service"

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

# 检查服务状态 
echo -e "${BLUE} 正在检查服务状态...${NC}"
sudo systemctl status youran.service 

# 提示完成 
echo -e "${GREEN} 下载和配置完成！${NC}"