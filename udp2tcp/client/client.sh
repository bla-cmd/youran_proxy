#!/bin/bash

# 定义下载链接
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/client/client"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/client/client.service"

# 定义目标路径
PROGRAM_PATH="/usr/local/bin/client"
SERVICE_PATH="/etc/systemd/system/client.service"

# 下载程序
echo "正在下载 client..."
curl -L -o client "$PROGRAM_URL"

# 下载服务文件
echo "正在下载 client.service..."
curl -L -o client.service "$SERVICE_URL"

# 移动程序到目标目录并设置可执行权限
sudo mv client "$PROGRAM_PATH"
sudo chmod +x "$PROGRAM_PATH"

# 修改服务文件路径
sudo sed -i "s|ExecStart=.*|ExecStart=$PROGRAM_PATH|g" client.service

# 移动服务文件到 systemd 目录
sudo mv client.service "$SERVICE_PATH"


# 检查 /etc/client 目录是否存在
if [ ! -d "/etc/client" ]; then
  echo "目录 /etc/client 不存在，正在创建..."
  mkdir -p /etc/client
  if [ $? -eq 0 ]; then
    echo "目录创建成功。"
  else
    echo "目录创建失败，请检查权限。"
    exit 1
  fi
else
  echo "目录 /etc/client 已存在。"
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

# 创建 client.conf 并写入内容
cat <<EOF > /etc/client/client.conf
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
  echo "client.conf 文件创建成功，内容如下："
  cat /etc/client/client.conf
else
  echo "文件创建失败，请检查权限。"
  exit 1
fi


# 重新加载 systemd 管理器配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start client.service

# 设置服务开机自启动
sudo systemctl enable client.service

sudo systemctl status client.service

# 提示完成
echo "下载和配置完成！"
