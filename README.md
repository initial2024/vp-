# vp- · 可克隆的 Android SSH 网络代理方案

> **朋友自己申请云主机，克隆本仓库，照着教程即可搭建与示例相同的 TCP 优先代理链路。** 本仓库**不是 VPN 服务商、不是免费节点订阅，也不是云主机的备份**。不包含任何私人服务器、密钥或登录凭证。

## 这个仓库复刻什么？

```text
Android 浏览器 / 选定应用
     ↓ Android VPN (v2RayTun)
Xray 自定义配置：DNS:53 → 内置 DNS → DoH；其余 UDP → 拒绝
     ↓ TCP 出站 SOCKS5 127.0.0.1:1080
Termius（动态端口转发）或 Termux OpenSSH (-D)
     ↓ SSH 加密连接
你自己申请的 Linux 云主机（SSH 服务）
     ↓ 主机网络出口
互联网
```

**已实际打通的组合**：Android v2RayTun 5.27.84 / Xray 26.6.27 + 本地 SSH SOCKS5 `127.0.0.1:1080` + 本仓库中的 [TCP / DoH 配置](configs/AL-SSH-TCP-DNS-fixed.json)。这仅是一次设备与服务商环境中的成功记录，**不是跨机型/跨云厂商的兼容性保证**。

**协议边界**：OpenSSH `-D` 是 SOCKS 动态 **TCP** 转发，不是完整 UDP VPN；本配置把 DNS 53 请求送往 Xray DNS 出站，使用 Cloudflare 的 DoH 上游；其余 UDP 一律阻断。视频、游戏、语音、QUIC/HTTP3 可能退回 TCP 或失败，不能声称「所有应用都能用」。

## 快速开始（建议严格按顺序）

1. [申请/准备自己的 Linux SSH 云主机](docs/SERVER-SSH.zh-CN.md)。确认提供商允许 SSH 和对外 TCP 连接，拿到 **SSH 主机名、端口、用户名、认证方式**。**不要复制别人的主机地址或私钥**。
2. 克隆仓库（任选一种）：
   - **手机 Termux**：`pkg update && pkg install git openssh curl -y && git clone https://github.com/initial2024/vp-.git && cd vp-`
   - **电脑**：`git clone https://github.com/initial2024/vp-.git`
   - **不会用终端**：GitHub 仓库页面 → Code → Download ZIP → 手机解压。
3. [Android 完整图文式文字教程](docs/SETUP-ANDROID.zh-CN.md)：先用 Termius 设置 **SOCKS5 动态转发**，或在 Termux 用本仓库的 `scripts/start-tunnel.sh`；目标是让手机本机 **127.0.0.1:1080** 可连接。
4. 在 **v2RayTun → ＋ → 自定义配置 → 从本地导入自定义配置** 中选择 `configs/AL-SSH-TCP-DNS-fixed.json`，**不是**「手动输入」节点链接。
5. 在 v2RayTun **设置 → 路由设置 → 选定应用路由**，先仅让 Firefox 等**一个测试应用**使用 VPN；**Termius/Termux 必须不走该 VPN**，否则 SSH 自身可能出现路由回环。
6. 先连接 SSH 隧道，再启动 v2RayTun；关闭 Firefox 的 FoxyProxy 等旧代理设置，以免叠加代理。打开 [IPinfo](https://ipinfo.io) 检查 IP 是否为**你自己的云主机出口**；不要用示例他人的出口 IP 来验收。
7. 基础网页正常后，按需求扩大应用范围。后台运行、断线重连和 UDP 限制详见[故障排查](docs/TROUBLESHOOTING.zh-CN.md)。

## 仓库文件

| 路径 | 作用 |
| --- | --- |
| [configs/AL-SSH-TCP-DNS-fixed.json](configs/AL-SSH-TCP-DNS-fixed.json) | 已成功使用过的 Xray SOCKS + DNS + UDP 阻断配置；**无需替换云主机 IP** |
| [docs/SERVER-SSH.zh-CN.md](docs/SERVER-SSH.zh-CN.md) | 申请云主机与 SSH 安全条件 |
| [docs/SETUP-ANDROID.zh-CN.md](docs/SETUP-ANDROID.zh-CN.md) | 手机操作步骤（Termius 和 Termux 两种方式） |
| [docs/TROUBLESHOOTING.zh-CN.md](docs/TROUBLESHOOTING.zh-CN.md) | DNS、大量 accepted 日志、端口冲突、连接回环、重连 |
| [scripts/start-tunnel.sh](scripts/start-tunnel.sh) | Termux/Linux/macOS 用 SSH 动态端口转发启动脚本 |
| [scripts/check-socks.sh](scripts/check-socks.sh) | 使用 curl 测试本地 SOCKS5 和出口 IP |
| [scripts/validate-config.py](scripts/validate-config.py) | Python 标准库校验关键规则与端口 |

## 安全与隐私

- **仓库永远不放入** SSH 私钥、密码、云厂商 token、Cookie、会话文件、云主机个人控制台截图或实际私人机器的凭证。
- 本地端口只绑定 `127.0.0.1`；**不要绑定 `0.0.0.0:1080`**，否则可能把代理暴露给附近网络。
- 初次 SSH 连接必须核对服务器主机密钥指纹；不能为了「能连」而关闭主机密钥验证。
- 优先使用普通用户 + SSH 公钥认证，限制 SSH 登录权限；请勿擅自开放公网 SOCKS 端口。
- DoH 上游为 Cloudflare `1.1.1.1`，意味着 DNS 查询涉及该服务商；该示例不代表匿名、防追踪或所有 DNS 都绝对不泄漏。
- 免费/试用主机可能休眠、回收、限制流量或停止服务；请查看自己提供商的有效期、流量与可接受使用政策。
- Android 通常同时只能有一个系统 VPN；v2RayTun 与 v2rayNG 不要一起开启。
- **不要**将「导入成功」「VPN 已连接」当成「流量必然从自己的云主机出去」；实际以出口 IP、TCP 访问结果与日志共同确认。

## 技术依据

- [OpenSSH ssh(1)，-D dynamic forward](https://man.openbsd.org/ssh)
- [Xray DNS 配置](https://xtls.github.io/en/config/dns)
- [Xray DNS 出站](https://xtls.github.io/en/config/outbounds/dns)
- [v2RayTun Android 版本信息](https://github.com/LXST-CODE/v2RayTun/releases)

> 本项目是**网络配置示例和教程**，不提供可共享节点、虚假地址认证、绕过服务条款的建议或连接质量承诺。
