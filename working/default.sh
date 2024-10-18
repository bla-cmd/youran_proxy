#!/bin/bash

# 运行第一个脚本
echo "正在运行第一个脚本..."
bash <(curl -Ls https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/working/xray/default.sh)
if [ $? -eq 0 ]; then
  echo "第一个脚本执行成功！"
else
  echo "第一个脚本执行失败！请检查网络或脚本地址。" >&2
  exit 1
fi

# 运行第二个脚本
echo "正在运行第二个脚本..."
bash <(curl -Ls https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/udp2tcp/server/server.sh)
if [ $? -eq 0 ]; then
  echo "第二个脚本执行成功！"
else
  echo "第二个脚本执行失败！请检查网络或脚本地址。" >&2
  exit 1
fi

# 运行第三个脚本
echo "正在运行第三个脚本..."
bash <(curl -Ls https://ghproxy.cn/https://raw.githubusercontent.com/bla-cmd/YouRan_Proxy/master/l2tp/install.sh)
if [ $? -eq 0 ]; then
  echo "第三个脚本执行成功！"
else
  echo "第三个脚本执行失败！请检查网络或脚本地址。" >&2
  exit 1
fi

echo "所有脚本已成功执行完毕！"
