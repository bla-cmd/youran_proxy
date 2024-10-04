#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # 没有颜色

# 定义下载链接 
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server.service"

# 定义目标路径 
PROGRAM_PATH="/usr/local/bin/server"
SERVICE_PATH="/etc/systemd/system/server.service"

# 检查 server 是否已经存在
if [ -f "$PROGRAM_PATH" ]; then
  echo -e "${YELLOW}⚠️  server 已存在，跳过下载。${NC}"
else
  # 下载程序
  echo -e "${BLUE}🔄 正在下载 server...${NC}"
  curl -L -o server "$PROGRAM_URL"
  sudo mv server "$PROGRAM_PATH"
  sudo chmod +x "$PROGRAM_PATH"
  echo -e "${GREEN}✔️ server 下载并配置完成！${NC}"
fi

# 检查 server.service 是否已经存在
if [ -f "$SERVICE_PATH" ];then
  echo -e "${YELLOW}⚠️  server.service 已存在，跳过下载。${NC}"
else
  # 下载服务文件
  echo -e "${BLUE}🔄 正在下载 server.service...${NC}"
  curl -L -o server.service "$SERVICE_URL"
  sudo mv server.service "$SERVICE_PATH"
  echo -e "${GREEN}✔️ server.service 下载并配置完成！${NC}"
fi

# 检查 /etc/server 目录是否存在
if [ ! -d "/etc/server" ]; then
  echo -e "${BLUE}📁 目录 /etc/server 不存在，正在创建...${NC}"
  sudo mkdir -p /etc/server
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✔️ 目录创建成功。${NC}"
  else
    echo -e "${RED}❌ 目录创建失败，请检查权限。${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️  目录 /etc/server 已存在。${NC}"
fi

# 检查 server.conf 是否存在，存在则删除旧文件
if [ -f "/etc/server/server.conf" ]; then
  echo -e "${YELLOW}⚠️  server.conf 已存在，正在删除旧文件...${NC}"
  sudo rm /etc/server/server.conf
fi

# 尝试自动获取公网IP地址
ip_address=$(curl -s http://whatismyip.akamai.com/)
if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo -e "${GREEN}✔️ 获取到的公网IP地址为：$ip_address${NC}"
else
  echo -e "${RED}❌ 无法自动获取公网IP地址，请手动输入。${NC}"

  # 提示用户输入IP地址
  read -p "请输入需要转发的IP地址: " ip_address

  # 验证输入是否为有效的IP地址
  if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo -e "${GREEN}✔️ 输入的IP地址有效：$ip_address${NC}"
  else
    echo -e "${RED}❌ 输入的不是有效的IP地址，请重新运行脚本并输入正确的IP。${NC}"
    exit 1
  fi
fi

# 创建 server.conf 并写入内容 
echo -e "${BLUE}🔄 正在创建 server.conf 文件...${NC}"
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
  echo -e "${GREEN}✔️ server.conf 文件创建成功，内容如下：${NC}"
  cat /etc/server/server.conf
else
  echo -e "${RED}❌ 文件创建失败，请检查权限。${NC}"
  exit 1
fi

# 重新加载 systemd 管理器配置 
echo -e "${BLUE}🔄 重新加载 systemd 配置...${NC}"
sudo systemctl daemon-reload

# 启动服务 
echo -e "${BLUE}🔄 正在启动 server.service...${NC}"
sudo systemctl start server.service

# 设置服务开机自启动 
sudo systemctl enable server.service
echo -e "${GREEN}✔️ server.service 设置为开机自启动。${NC}"

# 检查服务状态
echo -e "${BLUE}🔄 正在检查服务状态...${NC}"
sudo systemctl status server.service

# 提示完成 
echo -e "${GREEN}✔️ 下载和配置完成！${NC}"
