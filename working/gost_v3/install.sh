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
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/gost_v3/gost"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/gost_v3/gost.service"

# 定义目标路径 
PROGRAM_PATH="/usr/local/bin/gost"
SERVICE_PATH="/etc/systemd/system/gost.service"

# 检查 gost 是否已经存在 
if [ -f "$PROGRAM_PATH" ]; then 
  echo -e "${YELLOW}  gost 已存在，跳过下载。${NC}"
else 
  # 下载程序 
  echo -e "${BLUE} 正在下载 gost...${NC}"
  curl -L -o gost "$PROGRAM_URL"
  sudo mv gost "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN} gost 下载并配置完成！${NC}"
fi 

# 检查 gost.service 是否已经存在 
if [ -f "$SERVICE_PATH" ]; then 
  echo -e "${YELLOW}  gost.service 已存在，跳过下载。${NC}"
else 
  # 下载服务文件 
  echo -e "${BLUE} 正在下载 gost.service...${NC}"
  curl -L -o gost.service "$SERVICE_URL"
  sudo mv gost.service "$SERVICE_PATH"
  echo -e "${GREEN} gost.service 下载并配置完成！${NC}"
fi 

# 检查 /etc/gost 目录是否存在 
if [ ! -d "/etc/gost" ]; then 
  echo -e "${BLUE} 目录 /etc/gost 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/gost
  if [ $? -eq 0 ]; then 
    echo -e "${GREEN} 目录创建成功。${NC}"
  else 
    echo -e "${RED} 目录创建失败，请检查权限。${NC}"
    exit 1 
  fi 
else 
  echo -e "${YELLOW}  目录 /etc/gost 已存在。${NC}"
fi 

# 检查 gost.yaml 是否存在，存在则删除 
if [ -f "/etc/gost/gost.yaml" ]; then 
  echo -e "${YELLOW}  gost.yaml 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/gost/gost.yaml
fi 

# 提示用户输入IP地址 
read -p "请输入需要转发的IP地址: " ip_address 

# 验证输入是否为有效的IP地址 
if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then 
  echo -e "${GREEN} 输入的IP地址有效：$ip_address${NC}"
else 
  echo -e "${RED} 输入的不是有效的IP地址，请重新运行脚本并输入正确的IP。${NC}"
  exit 1 
fi 

# 创建 gost.conf 并写入内容 
echo -e "${BLUE} 正在创建 gost.yaml 文件...${NC}"
cat <<EOF | sudo tee /etc/gost/gost.yaml
services: 
- name: service-0 
  addr: ":12345" 
  handler: 
    type: red 
    chain: chain-0 
    metadata: 
      sniffing: true
      ttl: 30s
  listener: 
    type: red 

chains: 
- name: chain-0 
  hops: 
  - name: hop-0 
    sockopts: 
        mark: 100   
    nodes: 
    - name: node-0 
      addr: "$ip_address:8090"  # 确保代理服务器的地址使用引号
      connector: 
        type: socks5  # 将连接器类型修改为 socks5
        metadata:
        auth:
            username: "admin"  # 代理用户名
            password: "@youran12345"  # 代理密码
      dialer: 
        type: tcp  # 保留 tcp 作为拨号类型


EOF

if [ $? -eq 0 ]; then 
  echo -e "${GREEN} gost.yaml 文件创建成功${NC}"
else 
  echo -e "${RED} 文件创建失败，请检查权限。${NC}"
  exit 1 
fi 

# 重新加载 systemd 管理器配置 
echo -e "${BLUE} 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload 

# 启动服务 
echo -e " 正在启动 gost.service...${NC}"
sudo systemctl restart gost.service 

# 设置服务开机自启动 
sudo systemctl enable gost.service 
echo -e "${GREEN} gost.service 设置为开机自启动。${NC}"

# 检查服务状态 
echo -e "${BLUE} 正在检查服务状态...${NC}"
sudo systemctl status gost.service 

# 提示完成 
echo -e "${GREEN} 下载和配置完成！${NC}"
