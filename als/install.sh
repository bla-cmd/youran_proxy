#!/bin/bash

# 定义下载链接
PROGRAM_URL="https://ghproxy.cn/https://raw.githubusercontent.com/PainterXIII/YouRan_Proxy/master/als/als-linux-amd64"
SERVICE_URL="https://ghproxy.cn/https://raw.githubusercontent.com/PainterXIII/YouRan_Proxy/master/als/als.service"

# 定义目标路径
PROGRAM_PATH="/usr/local/bin/als-linux-amd64"
SERVICE_PATH="/etc/systemd/system/als.service"

# 下载程序
echo "正在下载 als-linux-amd64..."
curl -L -o als-linux-amd64 "$PROGRAM_URL"

# 下载服务文件
echo "正在下载 als.service..."
curl -L -o als.service "$SERVICE_URL"

# 移动程序到目标目录并设置可执行权限
sudo mv als-linux-amd64 "$PROGRAM_PATH"
sudo chmod +x "$PROGRAM_PATH"

# 修改服务文件路径
sudo sed -i "s|ExecStart=.*|ExecStart=$PROGRAM_PATH|g" als.service

# 移动服务文件到 systemd 目录
sudo mv als.service "$SERVICE_PATH"

# 重新加载 systemd 管理器配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start als.service

# 设置服务开机自启动
sudo systemctl enable als.service

# 提示完成
echo "下载和配置完成！"
