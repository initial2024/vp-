#!/usr/bin/env bash
# Run on Termux/Linux/macOS: bash scripts/start-tunnel.sh USER HOST [PORT]
# SSH dynamic forwarding uses TCP SOCKS; it is not a UDP VPN.
set -euo pipefail
if [[ $# -lt 2 || $# -gt 3 ]]; then
  printf '用法: bash %s <SSH用户名> <SSH主机名> [SSH端口，默认22]\n' "$0" >&2
  exit 2
fi
user="$1"; host="$2"; port="${3:-22}"
if [[ -z "$user" || -z "$host" || ! "$port" =~ ^[0-9]+$ || "$port" -lt 1 || "$port" -gt 65535 ]]; then
  echo '参数不合法：用户名/主机名不能为空，端口必须是 1~65535。' >&2
  exit 2
fi
if [[ "$user" == *"@"* || "$host" == *"@"* || "$user" == -* || "$host" == -* ]]; then
  echo '请把 SSH 用户名、主机名分别填写，不能包含 @，不能以 - 开头。' >&2
  exit 2
fi
command -v ssh >/dev/null 2>&1 || { echo '缺少 ssh：Termux 中运行 pkg install openssh' >&2; exit 127; }
printf '启动本地 SOCKS5：127.0.0.1:1080，SSH：%s@%s:%s\n' "$user" "$host" "$port"
printf '请通过可信渠道核对 SSH host key 指纹。保持当前会话开启；Ctrl+C 停止。\n'
exec ssh -N -D 127.0.0.1:1080 -p "$port" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o StrictHostKeyChecking=ask \
  -- "${user}@${host}"
