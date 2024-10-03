#!/bin/bash

# 提示用户输入IP地址
read -p "请输入要转发的IP地址: " ip_address

# /etc/gost/config.json 和 /etc/gost/rawconf 的目标路径
config_path="/etc/gost/config.json"
rawconf_path="/etc/gost/rawconf"

# 检查文件是否存在，如果存在则删除
if [ -f "$config_path" ]; then
    rm -f "$config_path"
    echo "已删除现有的 $config_path 文件。"
fi

if [ -f "$rawconf_path" ]; then
    rm -f "$rawconf_path"
    echo "已删除现有的 $rawconf_path 文件。"
fi

# 创建新的 config.json 内容
config_content=$(cat <<EOF
{
    "Debug": false,
    "Retries": 0,
    "ServeNodes": [
        "tcp://:1701/$ip_address:1701",
        "udp://:1701/$ip_address:1701"
    ],
    "Routes": [
        {
            "Retries": 0,
            "ServeNodes": [
                "tcp://:4500/$ip_address:4500",
                "udp://:4500/$ip_address:4500"
            ]
        },
        {
            "Retries": 0,
            "ServeNodes": [
                "tcp://:500/$ip_address:500",
                "udp://:500/$ip_address:500"
            ]
        },
        {
            "Retries": 0,
            "ServeNodes": [
                "tcp://:1116/$ip_address:1116",
                "udp://:1116/$ip_address:1116"
            ]
        },
        {
            "Retries": 0,
            "ServeNodes": [
                "tcp://:1234/$ip_address:1234",
                "udp://:1234/$ip_address:1234"
            ]
        }
    ]
}
EOF
)

# 创建新的 rawconf 内容
rawconf_content=$(cat <<EOF
nonencrypt/1701#$ip_address#1701
nonencrypt/4500#$ip_address#4500
nonencrypt/500#$ip_address#500
nonencrypt/1116#$ip_address#1116
nonencrypt/1234#$ip_address#1234
EOF
)

# 确保 /etc/gost 目录存在
mkdir -p /etc/gost

# 创建新的 config.json 文件
echo "$config_content" > "$config_path"
echo "relay_default配置已创建并保存到 $config_path"

# 创建新的 rawconf 文件
echo "$rawconf_content" > "$rawconf_path"
echo "新的 rawconf 已创建并保存到 $rawconf_path"

# 重新启动 gost 服务
systemctl restart gost

# 检查服务状态
if [ $? -eq 0 ]; then
    echo "gost 服务已成功重启。"
else
    echo "gost 服务重启失败，请检查配置文件和服务状态。"
fi
