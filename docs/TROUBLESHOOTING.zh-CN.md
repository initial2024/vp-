# 03 · 故障排查与验收标准

[返回首页](../README.md) ｜ [Android 教程](SETUP-ANDROID.zh-CN.md)

先明确你在使用哪一段链路：**浏览器 → v2RayTun VPN → 本地 SOCKS5 127.0.0.1:1080 → SSH 隧道 → 你自己的云主机 → 网站**。不要一遇到问题就重新部署云服务器。

| 症状 | 优先判断 | 应执行的操作 |
| --- | --- | --- |
| Termius 能 SSH 登录，但 VPN 不能上网 | 动态转发未开启、端口错误、SSH 被 VPN 回环 | 先断 VPN，仅用原来的 SOCKS 浏览器测试；检查 B1 是否真的选择 Dynamic/SOCKS |
| `connection refused 127.0.0.1:1080` | 手机本机 1080 未监听 | 启动 Termius 转发或 Termux `ssh -D`；检查是否被占用 |
| 能导入 JSON，却打不开网站 | JSON 解析成功 ≠ HTTP 成功 | 先用 `bash scripts/check-socks.sh` 或浏览器 SOCKS 单独验收，再检查选定应用路由 |
| `tun-in >> AL-SSH` / `accepted tcp:...:443` | 只是**接受**了流量 | 检查 HTTPS 能否加载、出口 IP、后续 error/timeout 日志 |
| 很多 `accepted udp:...:53` 重复 | DNS 查询被反复发起，可能无响应 | **使用本仓库修复版 JSON**，检查 DoH 可达性；别当成成功证据 |
| `udp:...:23000` 或游戏/语音无法访问 | SSH SOCKS 无通用 UDP | 预期限制；此配置阻断非 DNS UDP，改用真正支持 UDP 的方案 |
| v2RayTun 已连接但 IP 还是移动网络 | 应用未纳入 VPN、代理链没生效 | 测试 Firefox 白名单、停用其他浏览器代理，再对比公网 IP |
| SSH 一会儿就断 | 安卓后台省电/云主机休眠/蜂窝网络切换 | 给 SSH 客户端后台权限、检查云商到期/流量、重连 SSH；不可承诺永久在线 |
| `Address already in use` | 1080 端口冲突 | 两种 SSH 客户端只开一个；其他软件不要占用 1080 |
| v2rayNG 列表只看到自己 | 安卓「读取应用列表」权限不足等 | 在手机系统权限中允许应用读取列表；此问题**不是** v2RayTun 的按钮 |
| 网页显示证书错误 | 服务器/网络被代理链影响或网站证书异常 | 不要忽略 TLS 报错；检查时间、网址、代理，停止输入敏感凭证 |

## 三段式验证：哪段失败就修哪段

### 1. 云主机 SSH

用 Termius 登录自己的 SSH。**确认 SSH 连通和主机密钥正确**。提供商 Web 终端能用，不代表从 Android 到 SSH 网关可用。

### 2. 本地 SOCKS（最关键）

**先断开 v2RayTun**。在 Termux（第二会话）执行：

```sh
cd ~/vp-
bash scripts/check-socks.sh
```

这个脚本使用 `curl --socks5-hostname 127.0.0.1:1080` 发起 HTTPS 请求。`--socks5-hostname` 允许让 SOCKS 代理处理域名而不是由本机先解析该目标。若失败，先修 SSH 转发或服务器，不要改 JSON。

不使用 Termux 的朋友，可在 Firefox + FoxyProxy 临时使用 SOCKS5 127.0.0.1:1080 访问 `https://ipinfo.io` 做同样测试。

### 3. VPN 客户端

SOCKS 测试通过后，关闭 Firefox 中的 FoxyProxy，打开 v2RayTun 并使用本仓库 JSON。先只代理 Firefox，**SSH 客户端仍直连**。分别打开：

- <https://1.1.1.1/cdn-cgi/trace>（TCP/HTTPS）
- <https://ipinfo.io>（域名 DNS + HTTPS + 公网出口）

查看 v2RayTun **设置 → Logcat**：如果错误，复制出现的 `error`、`failed`、`refused`、`timeout`、`unsupported` 前后少量行；大段 `accepted` 本身不够判断问题。

## 为什么修正版有效但不是所有网络都保证成功

配置的第一条路由规则将 **TCP/UDP 53** 的传统 DNS 请求交给 Xray `dns` 出站，内置 DNS 采用 Cloudflare DoH；第二条将**其他 UDP**交给 blackhole。未匹配的 TCP 走第一个 SOCKS 出站。

**已在一次用户环境中实际成功**，但 Android 私有 DNS、浏览器 DoH、v2RayTun 自身 TUN/DNS 的实现、云商出网策略都可能改变行为。DNS 上游本身也可能在你的网络不可达。本仓库的静态检查不等于端到端设备测试。

## 隐私、安全、风险边界

- Cloudflare DoH 解析器会处理 DNS 请求。HTTPS 仍依赖正确验证服务器证书。
- 手机侧只监听回环地址，严禁把 1080 公开到局域网/公网。
- SSH 首次连接不要禁用 host-key 检查，云服务器不要发布密码/私钥到 Git。
- Xray `UDP blackhole` 表示这些应用的 UDP 被丢弃，不代表它们被自动换成 TCP。
- 使用不受信任的服务商时，其服务器是实际网络出口，服务商仍可观察部分连接元数据。
- 云厂商若限制代理用途/流量/在线时间，务必遵守，不应通过脚本规避回收规则。
