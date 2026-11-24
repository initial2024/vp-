#!/usr/bin/env bash
# Simple test; does not assert DNS or UDP leak freedom.
set -euo pipefail
command -v curl >/dev/null 2>&1 || { echo '缺少 curl：Termux 中运行 pkg install curl' >&2; exit 127; }
echo '检查 127.0.0.1:1080 SOCKS5 → HTTPS 出口...'
ip="$(curl --fail --silent --show-error --connect-timeout 6 --max-time 20 \
  --socks5-hostname 127.0.0.1:1080 https://api.ipify.org)"
if [[ ! "$ip" =~ ^[0-9A-Fa-f:.]+$ ]]; then
  printf '出口返回异常，请核查代理：%s\n' "$ip" >&2
  exit 1
fi
printf '经本地 SOCKS5 检测到的出口 IP：%s\n' "$ip"
echo '请和自己云主机的实际出网 IP 对照；成功返回 ≠ VPN 已配置成功。'
