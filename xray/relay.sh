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
        "listen": null,
        "port": 1116,
        "protocol": "dokodemo-door",
        "settings": {
          "address": "$ip_address",
          "port": 1116,
          "network": "tcp,udp"
        },
        "streamSettings": {
          "network": "tcp",
          "security": "none",
          "tcpSettings": {
            "header": {
              "type": "none"
            }
          }
        },
        "tag": "inbound-1116",
        "sniffing": {}
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
