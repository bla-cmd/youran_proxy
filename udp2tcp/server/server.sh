#!/bin/bash

# 定义下载链接
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server.service"

# 定义目标路径
PROGRAM_PATH="/usr/local/bin/server"
SERVICE_PATH="/etc/systemd/system/server.service"

# 下载程序
echo "正在下载 server..."
curl -L -o server "$PROGRAM_URL"

# 下载服务文件
echo "正在下载 server.service..."
curl -L -o server.service "$SERVICE_URL"

# 移动程序到目标目录并设置可执行权限
sudo mv server "$PROGRAM_PATH"
sudo chmod +x "$PROGRAM_PATH"

# 修改服务文件路径
sudo sed -i "s|ExecStart=.*|ExecStart=$PROGRAM_PATH|g" server.service

# 移动服务文件到 systemd 目录
sudo mv server.service "$SERVICE_PATH"

# 检查 /etc/server 目录是否存在
if [ ! -d "/etc/server" ]; then
  echo "目录 /etc/server 不存在，正在创建..."
  mkdir -p /etc/server
  if [ $? -eq 0 ]; then
    echo "目录创建成功。"
  else
    echo "目录创建失败，请检查权限。"
    exit 1
  fi
else
  echo "目录 /etc/server 已存在。"
fi

# 提示用户输入IP地址
read -p "请输入需要转发的IP地址: " ip_address

# 验证输入是否为有效的IP地址
if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "输入的IP地址有效：$ip_address"
else
  echo "输入的不是有效的IP地址，请重新运行脚本并输入正确的IP。"
  exit 1
fi

# 创建 server.conf 并写入内容
cat <<EOF > /etc/server/server.conf
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
  echo "server.conf 文件创建成功，内容如下："
  cat /etc/server/server.conf
else
  echo "文件创建失败，请检查权限。"
  exit 1
fi

# 重新加载 systemd 管理器配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start server.service

# 设置服务开机自启动
sudo systemctl enable server.service

sudo systemctl status server.service

# 提示完成
echo "下载和配置完成！"
