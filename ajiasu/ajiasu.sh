#!/bin/bash

# 定义 ajiasu 可执行文件和配置文件的路径
AJIASU_BIN="/usr/local/bin/ajiasu"
AJIASU_CONF="/etc/ajiasu.conf"
LOGIN_SYNC_FILE="/etc/ajiasu/ajiasu-data/LoginSync.dat"

# 检查 ajiasu 可执行文件是否存在，若不存在则下载
if [ -f "$AJIASU_BIN" ]; then
    echo "ajiasu 可执行文件已存在，跳过下载"
else
    echo "正在下载 ajiasu 可执行文件..."
    curl -L -o $AJIASU_BIN https://ghproxy.cn/https://raw.githubusercontent.com/PainterXIII/YouRan_Proxy/master/ajiasu/ajiasu
    if [ $? -eq 0 ]; then
        echo "ajiasu 可执行文件下载成功"
    else
        echo "ajiasu 可执行文件下载失败"
        exit 1
    fi
    # 给予可执行权限
    chmod +x $AJIASU_BIN
fi

# 检查 ajiasu 配置文件是否存在，若不存在则下载
if [ -f "$AJIASU_CONF" ]; then
    echo "ajiasu 配置文件已存在，跳过下载"
else
    echo "正在下载 ajiasu 配置文件..."
    curl -L -o $AJIASU_CONF https://ghproxy.cn/https://raw.githubusercontent.com/PainterXIII/YouRan_Proxy/master/ajiasu/ajiasu.conf
    if [ $? -eq 0 ]; then
        echo "ajiasu 配置文件下载成功"
    else
        echo "ajiasu 配置文件下载失败"
        exit 1
    fi
fi

# 检查是否需要执行登录
if [ -f "$LOGIN_SYNC_FILE" ]; then
    echo "检测到 $LOGIN_SYNC_FILE，跳过 ajiasu 登录"
else
    echo "正在执行 ajiasu 登录..."
    ajiasu login
    if [ $? -eq 0 ]; then
        echo "ajiasu 已成功登录"
    else
        echo "ajiasu 登录失败"
        exit 1
    fi
fi

# 启动 ajiasu connect 并确保其在后台运行，SSH断开也不会终止
echo "正在启动 ajiasu connect 并保持在后台运行..."
nohup bash -c '
while true; do
    ajiasu connect
    if [ $? -ne 0 ]; then
        echo "ajiasu 连接失败，正在重试..."
        sleep 5
    else
        echo "ajiasu 已成功连接"
        break
    fi
done' > /dev/null 2>&1 &

echo "ajiasu connect 已在后台启动"
