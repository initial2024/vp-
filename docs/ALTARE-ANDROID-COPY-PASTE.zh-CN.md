# Altare Console + Android：从申请机器到代理成功的逐步操作（含可复制命令）

适用：朋友自行申请 **Altare Sandboxes** → Android **Termux（命令方案）** 或 **Termius（图形方案）** → **v2RayTun**。已成功验证的核心方案是 **SSH 动态 SOCKS5 + Xray TCP/DoH 修复配置**；不包含原使用者的云主机、密码、密钥。建议新手先走 **Termux 路线**，因为命令可逐步复制。

## 0. 先确认三个操作位置（绝不能混淆）

| 地方 | 在哪里打开 | 做什么 |
| --- | --- | --- |
| **Altare Console** | 手机浏览器打开 `https://console.altare.gg/` → Apps → 自己的 Sandbox → Console | 创建机器、读取 SSH 地址和端口、检查服务器出口 |
| **手机 Termux** | 手机安装 Termux 并打开其黑色终端 | 克隆仓库、运行 `ssh -N -D 127.0.0.1:1080`、检测 SOCKS |
| **手机 v2RayTun** | VPN App | 导入仓库 JSON，设置分应用，点击连接 |

**绝不能在 Altare 的网页控制台中运行手机用的 `ssh -D` 命令**：那样 SOCKS 会监听在云机器，而不是手机本地。

工作原理：`Firefox → Android VPN (v2RayTun) → Xray → 手机 127.0.0.1:1080 → 手机 SSH → Altare 云机 → 互联网`。

## 1. Altare 网页控制台：新建 Sandbox（只做一次）

1. 手机浏览器进入 <https://console.altare.gg/>，注册/登录**自己的账号**，选择自己的 Team。
2. 进入顶部/导航栏的 **Apps（应用）** → **New app（新建应用）** → **Software（软件）** → **Sandboxes**。这是 Altare 官方列出的创建路径；界面文字可能随更新略有变化。
3. 选择系统 **Ubuntu 24.04**（也可选平台当前提供的 Ubuntu 版本），输入自己的机器名称，如 `my-ssh-box`，选择可用区域、内存、CPU、存储等资源。
4. 在 SSH access/SSH 登录方式中选择 **SSH keys**（优先）或 **Password**；使用密码时至少 10 字符，**独立且不要提交 GitHub**。选择之前确认账户额度与实际付费规则，**不要默认以为一直免费**。
5. 完成创建，等待 Sandbox 状态为 Running/Started。在 Apps 中点击新创建的 Sandbox。
6. 找到 **Overview（概览）** 或 **Settings → SSH**；官方文档明确说明这两个页面有可以复制的 SSH 命令。格式可能像：

   ```sh
   ssh root@YOUR_ALTARE_SSH_HOST -p YOUR_ALTARE_SSH_PORT
   ```

7. 从自己的控制台准确抄下下面三个字段（**实例名称不是 SSH 主机名**）：

   | 字段 | 例子（仅占位） | 用在哪里 |
   | --- | --- | --- |
   | 用户名 | `root`（以自己控制台命令为准） | Termius / Termux |
   | SSH 主机 | `YOUR_ALTARE_SSH_HOST` | Termius / Termux |
   | SSH 端口 | `YOUR_ALTARE_SSH_PORT`（可能不等于 22） | Termius / Termux |

8. 请保持 **Sandbox 可运行**。如果 Settings → General 开启了 **Pause when idle**，实例空闲时可能暂停；此教程**不提供规避平台限制的保活脚本**。确认平台使用条款允许 SSH TCP 转发。

官方依据：[Altare Sandboxes](https://docs.altare.gg/sandboxes) · [Altare Connecting](https://docs.altare.gg/platform/connecting)。

### 1.1 在 **Altare 网页 Console** 复制执行的检查代码

在自己 Sandbox 的 **Console/控制台**，先粘贴这一组**只读**命令：

```sh
whoami
cat /etc/os-release | head -n 6
curl -4 --connect-timeout 8 --max-time 20 -fsS https://api.ipify.org
echo
```

**预期**：`whoami` 通常显示 `root`；系统信息显示 Ubuntu/Debian 等；`curl` 输出云机的**出口公网 IP**，记在自己的私密笔记中。此 IP **不一定等于 SSH 网关主机名解析到的 IP**。

若提示 `curl: command not found`，且使用 Ubuntu/Debian，可选运行：

```sh
apt-get update && apt-get install -y curl
```

此方案 **不需要** 在 Altare 服务器装 Xray、v2RayTun、WireGuard，也**不需要**开启公网 1080、额外端口或 `systemctl enable ssh`（Altare Sandbox 通常没有 systemd）。

## 2. 在 Android 手机上安装 Termux、克隆本仓库

**为什么选 Termux？** 它能在安卓本地运行 `ssh -D`，比不同版本的 Termius 菜单更易复刻。Termux 官方安装：[F-Droid](https://f-droid.org/packages/com.termux/) 或 [GitHub Releases](https://github.com/termux/termux-app/releases)；不要混装不同签名来源的软件包。

1. 安装 Termux，第一次打开会看到黑色命令行。
2. 在 **Termux（不是 Altare Console）** 复制下面 5 行，一行运行成功后再执行下一行：

```sh
pkg update -y
pkg install -y git openssh curl python
git clone https://github.com/initial2024/vp-.git
cd vp-
bash scripts/android-bootstrap.sh
```

3. 执行 `android-bootstrap.sh` 后，允许系统弹出的 Termux 文件访问权限。脚本会校验 JSON，并把配置放到 **Download/vp-/AL-SSH-TCP-DNS-fixed.json**；如果文件权限被拒绝，请到手机系统设置授权 Termux 的文件访问后重跑。
4. 如果 `git clone` 提示目录已存在，请改为：

```sh
cd ~/vp-
git pull --ff-only
bash scripts/android-bootstrap.sh
```

**预期**：最后显示配置已复制到 Download/vp-；文件管理器可在“下载”里找到 JSON。不要把 JSON 内容直接粘到 v2RayTun 的“手动输入节点链接”中。

## 3. 手机 Termux：建立 SSH 动态 SOCKS5（核心步骤）

1. 回到 Altare 网页的 **Settings → SSH**，核对 SSH 登录命令。准备**自己的** SSH 主机、端口与用户名。
2. 再回到手机 **Termux**，确保当前在仓库目录：

```sh
cd ~/vp-
```

3. 执行下行命令；**把三个占位值替换为自己机器实际信息，不可照抄占位文本**：

```sh
bash scripts/start-tunnel.sh root YOUR_ALTARE_SSH_HOST YOUR_ALTARE_SSH_PORT
```

该脚本等价于这条标准 OpenSSH 命令：

```sh
ssh -N -D 127.0.0.1:1080 -p YOUR_ALTARE_SSH_PORT root@YOUR_ALTARE_SSH_HOST
```

4. 首次连接可能出现 `The authenticity of host ... can't be established`：通过 Altare 可信渠道核对 SSH 主机密钥指纹，再确认。**不要**为了方便关闭指纹验证。
5. 如采用密码认证，输入的是**自己 Sandbox 的 SSH 密码**（输入时不会显示星号，属于正常现象）；采用密钥则按自己的密钥方式认证。
6. **连接成功时不出现远程 Shell/终端停住，通常是正常的**：`-N` 表示只做端口转发，程序会一直在前台保持会话。**不要退出 Termux，也不要 Ctrl+C**。转发监听在手机 **127.0.0.1:1080**。
7. 需要停止时先断开 v2RayTun，再返回 Termux 会话按 **Ctrl+C**。

### 3.1 新开第二个 Termux 会话，检测隧道

保留上个会话，在 Termux 左侧会话抽屉中新增第二会话；执行：

```sh
cd ~/vp-
bash scripts/check-socks.sh
```

若显示 `经本地 SOCKS5 检测到的出口 IP：...`，应与第 1.1 节的**自己服务器出口 IP**一致。这个测试只证明 **Termux → 本地 SOCKS → 云服务器 → HTTPS**，还没有测试 v2RayTun。

如果失败：检查 Altare 机器是否 Running、SSH 主机端口是否正确、手机当前网络是否能连接 SSH、是否已在第一个会话正确运行 `ssh -D`。**不要先去修改 v2RayTun。**

### 3.2 不想装 Termux？Termius 图形化替代方法

Termius **Hosts → Add/New Host** 填自己的 Altare SSH Host、Port、Username、认证信息；先连接登录核实主机指纹。然后在 **Port Forwarding → Dynamic/SOCKS**（如果你的版本/套餐有该功能）创建手机本地 **127.0.0.1:1080** 的动态转发，关联这个 SSH Host 并启动。

**SSH 登录成功 ≠ 端口转发已启动；** 不要把 **Local（固定目标）转发**误当作 **Dynamic/SOCKS**。如果看不到 Dynamic，使用上面的 Termux 路线。Termius 与 Termux 不得同时占用 1080。

Termius 路线可直接在手机浏览器打开并下载 [JSON 原文件](https://raw.githubusercontent.com/initial2024/vp-/main/configs/AL-SSH-TCP-DNS-fixed.json) 至 Download，不必在 Termux 运行 bootstrap。

## 4. 在 v2RayTun 导入 JSON 并设置按应用路由

1. 手机安装 v2RayTun（建议从官方应用发布渠道），**先断开** v2rayNG / 其他 Android VPN。已经验证过的客户端参考版本为 **v2RayTun 5.27.84 / Xray 26.6.27**，菜单随版本可能不同。
2. 打开 v2RayTun → 右上角 **＋** → **自定义配置** → **从本地导入自定义配置**。
3. 在系统文件选择器打开 **Download → vp- → AL-SSH-TCP-DNS-fixed.json**。如果你是用浏览器直接下载的文件，选择实际下载位置。
4. 选中刚导入的自定义配置；**不要**用“手动输入”粘一行 `127.0.0.1:1080`，也不要粘 `ssh -D` 命令。
5. 打开 **v2RayTun 设置 → 路由设置 → 选定应用路由（Routing of selected applications）**。首次测试时选择 **只让 Firefox 走 VPN** 的模式，并确保 **Termux 或 Termius 不在 VPN 里**。某版本可能把勾选解释成“绕过”而不是“使用”，务必看说明，不能只按按钮颜色判断。
6. Firefox 关闭以前安装的 FoxyProxy SOCKS 规则，避免重复代理。
7. 保持第 3 步 SSH 正在运行，回 v2RayTun 点击连接，允许 Android VPN 权限。**先 SSH 后 VPN**。
8. 初次仅在 Firefox 测试；确认无 SSH 回环后再考虑扩大应用范围。Android 不宜同时运行 v2RayTun 和 v2rayNG 两个系统 VPN。

**JSON 内 `127.0.0.1:1080` 不用修改成 Altare 的机器 IP！** 它指向的是**Android 本地**运行的 SSH SOCKS。配置还把传统 DNS:53 导向 Xray 的 DNS/DoH，将其他 UDP 丢弃；这是 TCP 优先网络，不是完整 UDP VPN。

## 5. 怎么判断“真的能用”，而不是 VPN 假连接？

1. **手机直连基线**：VPN 断开、Firefox 关闭 FoxyProxy 时打开 <https://ipinfo.io>，记录手机当前出口 IP。
2. **本地 SOCKS**：运行 `bash scripts/check-socks.sh`，输出应是自己 Altare 机器的公网出口。
3. **VPN TCP**：v2RayTun 连接后在 Firefox 打开 <https://1.1.1.1/cdn-cgi/trace>。
4. **VPN DNS + HTTPS**：再打开 <https://ipinfo.io>，网页可加载且出口 IP 应和自己的 Altare 出口相符（不同于手机直连 IP）。
5. 打开两个普通 HTTPS 网站，确认持续加载。必要时去 **v2RayTun → 设置 → Logcat** 查看 `error`、`timeout`、`refused`；`accepted tcp:...:443` 只能代表接收连接请求，**不代表请求已经成功完成**。

### 错误速查

| 现象 | 首先处理 |
| --- | --- |
| `connection refused 127.0.0.1:1080` | Termux SSH `-D` 没有运行 / Termius Dynamic 未启动 |
| VPN 已连，全部网页打不开 | 暂时断 VPN，先执行 SOCKS 脚本；再看分应用是否排错 |
| 大量 `accepted udp:...:53` | 确认导入 **AL-SSH-TCP-DNS-fixed.json** 而非旧版配置 |
| `accepted tcp:...:443` 但网页超时 | 不能仅凭 accepted 判成功；检查 SSH 转发和 DNS |
| VPN IP 还是蜂窝网络 IP | 浏览器没有走 VPN、旧代理重复或路由选反 |
| 一段时间后断线 | Android 后台省电限制 / SSH 网络切换 / Sandbox 休眠 |
| 游戏/通话/UDP 应用不通 | 预期协议限制，不能靠调整 SSH `-D` 获得通用 UDP |

## 6. 长期运行与安全边界

- **连接顺序**：开启 Sandbox → 手机 Termux/Termius 运行 SSH SOCKS → v2RayTun；停止顺序相反。
- Android 可能限制后台进程；给 Termux/Termius 与 v2RayTun 必要的后台权限，但无法保证系统永不杀进程。
- **Altare Sandbox 和 Altare Go 不一样**：Go 临时机器到期会销毁；此教程使用 Sandbox。Sandbox 的 **Pause when idle** 可暂停服务，参见官方文档。遵守平台限额，不提供违反条款的刷活跃度方案。
- **绝不要公开** SSH 密码、私钥、Token 或机器管理后台；不需要在云主机开放 1080。手机 SOCKS 只监听 `127.0.0.1`，不绑定 `0.0.0.0`。
- DNS 的 DoH 上游为 Cloudflare 1.1.1.1；**不保证匿名或绝对无 DNS 泄漏**。普通 SSH 动态 SOCKS 主要转发 TCP；配置阻断非 DNS UDP，游戏、实时语音或 QUIC 可能无法正常工作。
- 朋友**克隆仓库只会复制文件**，不会获得你的机器或账号；实际连接质量与有效期要在朋友自己的 Altare 机器实测。

## 7. 真正只需复制的命令总表

**在 Altare 网页 Console（仅检查服务器）：**

```sh
whoami
cat /etc/os-release | head -n 6
curl -4 --connect-timeout 8 --max-time 20 -fsS https://api.ipify.org; echo
```

**在 Android Termux（首次安装、克隆并准备 JSON）：**

```sh
pkg update -y
pkg install -y git openssh curl python
git clone https://github.com/initial2024/vp-.git
cd vp-
bash scripts/android-bootstrap.sh
```

**在 Android Termux 第一会话（替换为自己的机器信息）：**

```sh
cd ~/vp-
bash scripts/start-tunnel.sh root YOUR_ALTARE_SSH_HOST YOUR_ALTARE_SSH_PORT
```

**在 Android Termux 第二会话（测试本地 SOCKS）：**

```sh
cd ~/vp-
bash scripts/check-socks.sh
```

**在 v2RayTun（点击操作，不能当成命令执行）：**

```text
+ → 自定义配置 → 从本地导入自定义配置
Download/vp-/AL-SSH-TCP-DNS-fixed.json
设置 → 路由设置 → 仅 Firefox 走 VPN；排除 Termux/Termius
先 SSH 后 VPN → 访问 https://ipinfo.io 检查云主机出口
```

## 文档校验范围

官方参考：
- <https://docs.altare.gg/sandboxes>
- <https://docs.altare.gg/platform/connecting>
- <https://docs.altare.gg/cli/go>
- <https://man.openbsd.org/ssh>
- <https://github.com/termux/termux-app/releases>

此教程的 SSH/JSON 路径来自已成功的个人环境；仓库的离线校验不等于对朋友机器的真实端到端验收。
