# 02 · Android 从零复刻教程（手机优先）

[返回首页](../README.md) ｜ [准备服务器](SERVER-SSH.zh-CN.md) ｜ [故障排查](TROUBLESHOOTING.zh-CN.md)

**目标**：朋友使用**自己的** SSH 云主机，通过 SSH 动态转发在 Android 建立 `127.0.0.1:1080` SOCKS5，然后用 v2RayTun 接管选定应用的 TCP 流量。此方案不要求朋友共享原用户的机器或账户。

## A. 下载/克隆仓库

**手机不熟悉命令行：**

1. 浏览器打开 <https://github.com/initial2024/vp->。
2. 点击绿色 **Code** → **Download ZIP** → 解压。
3. 最终需要找到 `configs/AL-SSH-TCP-DNS-fixed.json` 文件；不要只下载 README。

**用 Termux 真正克隆仓库：**

```sh
pkg update
pkg install git openssh curl -y
git clone https://github.com/initial2024/vp-.git
cd vp-
```

`git clone` 复制的是**开源教程、脚本、配置文件**，不会复制云主机、密钥、VPN 凭证或任何节点账户。

## B. 先建立本地 SOCKS5（二选一）

### B1. Termius 图形界面（已实际使用过的路径）

1. 手机安装并打开 Termius，在 Host / New Host 中录入**自己的** SSH 主机名、SSH 映射端口、用户名和登录方式。
2. 连接 SSH；初次连接核对**真实服务器 SSH 主机密钥指纹**。能看到 Shell 表示 SSH 登录正常，**不等于动态端口转发已打开**。
3. 在 Termius 的 **Port Forwarding / 端口转发** 功能中选择 **Dynamic / SOCKS**（具体名称随版本变化）。创建手机本机监听端口：**127.0.0.1:1080**。
4. 若存在 Forward / Tunnel 的单独启用按钮，务必启动并保持 SSH 会话。**不要**误建成「Local（固定目的地的本地转发）」或「Remote」转发。
5. 若 Termius 版本不提供 Dynamic 转发，可以用下面 B2 的 Termux 方案。

> Termius 界面与某些功能是否提供，取决于实际版本或套餐；本教程不保证所有安装版本都有完全相同的按钮。

### B2. Termux SSH 方案（无需 Termius）

1. 已在 A 节通过 `pkg install git openssh curl -y` 安装客户端。
2. 在已克隆的仓库目录运行（**这三项需要替换为自己的值**）：

```sh
bash scripts/start-tunnel.sh YOUR_USER YOUR_SSH_HOST YOUR_SSH_PORT
```

3. 脚本调用 OpenSSH `ssh -N -D 127.0.0.1:1080`；显示指纹提示时先核对，按提示认证；**程序正常保持前台，不会自行返回命令提示符**。
4. 不要结束脚本所在的 Termux 会话；安卓省电设置为 Termux 允许后台活动。运行其他终端命令可开 Termux 第二会话。
5. 可在第二会话运行：

```sh
cd ~/vp-
bash scripts/check-socks.sh
```

如果提示未找到 `curl`，先 `pkg install curl -y`；脚本将输出**云主机出口公网 IP**，命令失败说明 SOCKS 链路还没有打通。

**注意：** B1 和 B2 只选一个。不要让两个程序同时监听手机的 `127.0.0.1:1080`，否则会端口冲突。

## C. 安装并导入 v2RayTun

实际验证过的设备版本是 **v2RayTun Android 5.27.84 / Xray 26.6.27**。其他版本的布局和导入兼容性可能不同。

1. 打开 v2RayTun，保持断开。
2. 点击连接页的 **＋ → 自定义配置 → 从本地导入自定义配置**。
3. 选择从仓库克隆/解压得到的文件 `configs/AL-SSH-TCP-DNS-fixed.json`。
4. 出现新的自定义配置后选中它。**不要**把 JSON 粘贴到「手动输入」节点链接框，也不要只输入 `127.0.0.1:1080`。
5. 这个文件中 **`127.0.0.1:1080` 是手机 Termius/Termux 提供的 SOCKS**；`127.0.0.1:10808` 是 Xray 本地入站；两者不能与其他本地服务冲突。
6. 如果手机里已有 VLESS、WireGuard 等配置，直接保留，不需要删除。

## D. 关键：按应用路由，绕过 SSH 客户端

打开 **v2RayTun → 设置 → 路由设置**，寻找「选定应用路由 / Routing of selected applications」。

**首次测试用白名单/仅选中应用使用 VPN 模式**：只选择 Firefox（或者一个干净的浏览器）。**不要让 Termius/Termux 的 SSH 连接进入 v2RayTun 自己的 VPN**，否则可能产生 `VPN → SOCKS → SSH → VPN` 的死循环。

不同版本的「绕行」文字含义可能相反，请根据页面说明确认实际是**只代理选定应用**还是**排除选定应用**，不要只看开关颜色。若无法保证 Termius/Termux 不进入 VPN，**先不启用全局**。

Android 通常不能同时激活两个 VpnService VPN；测试时断开 v2rayNG/其他 VPN。

## E. 连接顺序与验证

1. 先在 Termius 或 Termux 启动 **SSH + Dynamic SOCKS 1080**。
2. 确认已经把 SSH 客户端排除在 VPN 外；v2RayTun 中选中新配置，点击连接并允许 Android VPN 权限。
3. Firefox 关闭以前配置的 FoxyProxy（否则可能重复代理）。
4. 打开 <https://1.1.1.1/cdn-cgi/trace>（用于尽量减小域名解析干扰的 TCP/HTTPS 测试）。
5. 再打开 <https://ipinfo.io>。浏览器应显示**自己云主机的出口 IP**，而不是手机蜂窝网络 IP。要验证是否真的走代理，先断开 VPN 比较这两个 IP。
6. 试着访问多个普通 HTTPS 网站，观察是否正常加载。导入成功、`accepted` 日志以及 VPN 图标，单独都**不能证明**请求已真正完成。

### 以后怎么长期用？

启动顺序始终为 **先 SSH SOCKS → 后 v2RayTun**。停用顺序相反。

在 vivo/Android 的应用电池管理中，给 SSH 客户端和 v2RayTun 开启必要的后台运行权限；但这并不保证操作系统永不终止进程，重启或断网后可能要重新连接。不要为了「保活」关闭 Android 整体安全防护。

## F. 配置具体工作原理

```text
DNS :53 TCP/UDP ─→ Xray dns-hijack ─→ Cloudflare DoH (https://1.1.1.1/dns-query)
其他 UDP     ─→ blackhole（阻断）
其余 TCP     ─→ AL-SSH SOCKS 出站 ─→ 手机本地 127.0.0.1:1080 ─→ SSH ─→ 自己的云主机
```

这是一套**TCP 为主的代理，不是完整 UDP VPN**。DNS 由 Cloudflare DoH 服务处理，浏览器「安全 DNS」、Android 私有 DNS 与按应用路由仍可能影响实际解析路径；不要承诺绝对无 DNS 泄漏。需要通话、游戏、完整 UDP 时应重新选用原生支持 UDP 的服务器协议，不能强行把 SSH `-D` 当作 UDP VPN。
