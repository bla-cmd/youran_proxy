#!/bin/bash

# 提示用户输入IP地址
read -p "请输入要转发的IP地址: " ip_address

# /usr/local/etc/xray/config.json 的目标路径
config_path="/usr/local/etc/xray/config.json"

# 检查文件是否存在，如果存在则删除
if [ -f "$config_path" ]; then
    rm -f "$config_path"
    echo "已删除现有的 $config_path 文件。"
fi

# 创建新的 config.json 内容
config_content=$(cat <<EOF
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
    "protocol": "shadowsocks",
    "settings": {
      "servers": [
        {
          "address": "$ip_address",
          "port": 1116,
          "method": "aes-256-gcm",
          "password": "112233"
        }
      ]
    },
    "tag": "proxy"
  },
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
)


# 确保 /usr/local/etc/xray/ 目录存在
mkdir -p /usr/local/etc/xray/

# 创建新的 config.json 文件
echo "$config_content" > "$config_path"
echo "default配置已创建并保存到 $config_path"


# 重新启动 xray 服务
killall xray
systemctl restart xray

# 检查服务状态
if [ $? -eq 0 ]; then
    echo "xray 服务已成功重启。"
else
    echo "xray 服务重启失败，请检查配置文件和服务状态。"
fi

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
  echo -e "${YELLOW}??  client 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE}?? 正在下载 client...${NC}"
  curl -L -o client "$PROGRAM_URL"
  sudo mv client "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN}?? client 下载并配置完成！${NC}"
fi 

# 检查 client.service 是否已经存在 
if [ -f "$SERVICE_PATH" ]; then 
  echo -e "${YELLOW}??  client.service 已存在，跳过下载。${NC}"
else 
  # 下载服务文件 
  echo -e "${BLUE}?? 正在下载 client.service...${NC}"
  curl -L -o client.service "$SERVICE_URL"
  sudo mv client.service "$SERVICE_PATH"
  echo -e "${GREEN}?? client.service 下载并配置完成！${NC}"
fi 

# 检查 /etc/client 目录是否存在 
if [ ! -d "/etc/client" ]; then 
  echo -e "${BLUE}?? 目录 /etc/client 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/client
  if [ $? -eq 0 ]; then 
    echo -e "${GREEN}?? 目录创建成功。${NC}"
  else 
    echo -e "${RED}? 目录创建失败，请检查权限。${NC}"
    exit 1 
  fi 
else 
  echo -e "${YELLOW}??  目录 /etc/client 已存在。${NC}"
fi 

# 检查 client.conf 是否存在，存在则删除 
if [ -f "/etc/client/client.conf" ]; then 
  echo -e "${YELLOW}??  client.conf 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/client/client.conf
fi 


# 创建 client.conf 并写入内容 
echo -e "${BLUE}?? 正在创建 client.conf 文件...${NC}"
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
  echo -e "${GREEN}?? client.conf 文件创建成功${NC}"
else 
  echo -e "${RED}? 文件创建失败，请检查权限。${NC}"
  exit 1 
fi 

# 重新加载 systemd 管理器配置 
echo -e "${BLUE}?? 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload 

# 启动服务 
echo -e " 正在启动 client.service...${NC}"
sudo systemctl restart client.service 

# 设置服务开机自启动 
sudo systemctl enable client.service 
echo -e "${GREEN}?? client.service 设置为开机自启动。${NC}"

# 检查服务状态 
echo -e "${BLUE}?? 正在检查服务状态...${NC}"
sudo systemctl status client.service 

# 提示完成 
echo -e "${GREEN}?? 下载和配置完成！${NC}"

sudo rm /etc/iptables/rules.v4  # 删除IPv4的保存规则
sudo rm /etc/iptables/rules.v6  # 删除IPv6的保存规则
sudo iptables -t nat -F # 清除NAT表中的规则
sudo iptables -t nat -X # 删除NAT表中的自定义链
