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
    "balancers": [
      {
        "tag": "loadbalance-1701",
        "selector": [
          "outbound-1701-1",
          "outbound-1701-2"
        ]
      },
      {
        "tag": "loadbalance-4500",
        "selector": [
          "outbound-4500-1",
          "outbound-4500-2"
        ]
      },
      {
        "tag": "loadbalance-500",
        "selector": [
          "outbound-500-1",
          "outbound-500-2"
        ]
      },
      {
        "tag": "loadbalance-1116",
        "selector": [
          "outbound-1116-1",
          "outbound-1116-2"
        ]
      },
      {
        "tag": "loadbalance-1234",
        "selector": [
          "outbound-1234-1",
          "outbound-1234-2"
        ]
      }
    ],
    "rules": [
      {
        "inboundTag": ["inbound-1701"],
        "outboundTag": "loadbalance-1701",
        "type": "field"
      },
      {
        "inboundTag": ["inbound-4500"],
        "outboundTag": "loadbalance-4500",
        "type": "field"
      },
      {
        "inboundTag": ["inbound-500"],
        "outboundTag": "loadbalance-500",
        "type": "field"
      },
      {
        "inboundTag": ["inbound-1116"],
        "outboundTag": "loadbalance-1116",
        "type": "field"
      },
      {
        "inboundTag": ["inbound-1234"],
        "outboundTag": "loadbalance-1234",
        "type": "field"
      },
      {
        "ip": ["geoip:private"],
        "outboundTag": "blocked",
        "type": "field"
      },
      {
        "outboundTag": "blocked",
        "protocol": ["bittorrent"],
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
      "port": 1701,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0",
        "port": 1701,
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
      "tag": "inbound-1701",
      "sniffing": {}
    },
    {
      "listen": null,
      "port": 4500,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0",
        "port": 4500,
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
      "tag": "inbound-4500",
      "sniffing": {}
    },
    {
      "listen": null,
      "port": 500,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0",
        "port": 500,
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
      "tag": "inbound-500",
      "sniffing": {}
    },
    {
      "listen": null,
      "port": 1116,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0",
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
    },
    {
      "listen": null,
      "port": 1234,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0",
        "port": 1234,
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
      "tag": "inbound-1234",
      "sniffing": {}
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-1701-1",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.60.153",
        "port": 1701
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-1701-2",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.168.247",
        "port": 1701
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-4500-1",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.60.153",
        "port": 4500
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-4500-2",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.168.247",
        "port": 4500
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-500-1",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.60.153",
        "port": 500
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-500-2",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.168.247",
        "port": 500
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-1116-1",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.60.153",
        "port": 1116
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-1116-2",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.168.247",
        "port": 1116
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-1234-1",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.60.153",
        "port": 1234
      }
    },
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "tag": "outbound-1234-2",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      },
      "settings": {
        "address": "36.138.168.247",
        "port": 1234
      }
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
