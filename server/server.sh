#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 结束所有 nginx 进程
echo -e "${GREEN}正在结束所有 nginx 进程...${NC}"
killall nginx

# 卸载 nginx 及相关组件
echo -e "${GREEN}正在卸载 nginx, nginx-common, nginx-extras...${NC}"
apt remove -y nginx nginx-common nginx-extras

# 安装 Xray
echo -e "${GREEN}正在安装 Xray...${NC}"
bash -c "$(curl -L https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/xray/install-release.sh)" @ install

# 运行 relay.sh 脚本
echo -e "${GREEN}正在运行 relay.sh...${NC}"
bash <(curl -Ls https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/xray/relay.sh)

# 运行 udp2tcp client 脚本
echo -e "${GREEN}正在运行 udp2tcp client 脚本...${NC}"
bash <(curl -Ls https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/client/client.sh)

echo -e "${GREEN}所有步骤完成！${NC}"
