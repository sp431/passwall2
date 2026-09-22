# PassWall2

OpenWrt PassWall2 代理工具的源码、安装包和配置指南，适配两种路由器型号。

## PassWall 与 PassWall2 的区别

| 特性 | PassWall | PassWall2 |
|------|----------|-----------|
| 配置方式 | 单一全局配置 | 分流配置（ACL） |
| DNS 处理 | 基础 DNS 分流 | 增强 DNS 分流 |
| 访问控制 | 基础 ACL | 高级 ACL（按源 IP 分流） |
| 订阅 | 支持订阅 | 支持订阅+转换 |
| 节点类型 | 基础类型 | 更多类型（含 Hysteria2, Naive） |
| 适用场景 | 简单代理需求 | 复杂分流需求 |

## 支持设备

| 型号 | 架构 | 系统 | 包管理器 | 说明 |
|------|------|------|----------|------|
| Cudy TR3000 | aarch64_cortex-a53 | OpenWrt 25.12.4 | apk | 256MB 内存，PassWall2 26.9.16 |
| Tenda BE12 Pro | aarch64_cortex-a53 | OpenWrt SNAPSHOT r34613（内核 6.18.31） | apk | 512MB/overlay 65MB，**未装 PassWall2**，但本仓库核心 apk（Xray/chinadns-ng/geoview/geo）被该设备的 **PassWall 一代**复用 |
| GL.iNet GL-SFT1200 | mipsel (mips32r2) | OpenWrt 18.06 | opkg | 116MB 内存，未安装 PassWall2 |

> 本仓库的核心 apk 是静态编译的 Go 程序（Xray/chinadns-ng/geoview 等），**不挑内核版本**，可跨 aarch64 设备复用（Tenda BE12 Pro 内核 6.18.31 实测可用）。
> 仓库根已加 `.gitattributes`（`eol=lf`），Windows 检出也保持 LF。

## 目录结构

```
passwall2/
├── README.md                               # 本文件
├── .gitignore
├── rudy-TR3000/                            # Cudy TR3000 (aarch64)
│   ├── README.md                           # 安装说明 + 踩坑记录
│   ├── scripts/
│   │   └── install-passwall2.sh            # 一键安装脚本（含 world 约束防护）
│   ├── src/                                # PassWall2 源码
│   │   ├── etc/
│   │   │   └── init.d/
│   │   │       ├── passwall2              # 主服务 init 脚本
│   │   │       └── passwall2_server        # 服务器端 init 脚本
│   │   └── usr/
│   │       └── lib/lua/luci/
│   │           ├── controller/             # LuCI 菜单控制器
│   │           ├── model/cbi/passwall2/      # LuCI 配置页面模型
│   │           ├── view/passwall2/           # LuCI 视图模板
│   │           └── i18n/                     # 多语言翻译
│   │       └── share/passwall2/             # PassWall2 核心脚本
│   │           ├── 0_default_config         # 默认配置
│   │           ├── app.sh                   # 主应用脚本
│   │           ├── utils.sh                 # 工具函数
│   │           ├── iptables.sh              # iptables 防火墙规则
│   │           ├── nftables.sh              # nftables 防火墙规则
│   │           ├── monitor.sh              # 进程监控
│   │           ├── subscribe.lua           # 订阅管理
│   │           ├── rule_update.lua          # 规则更新
│   │           ├── helper_dnsmasq.lua       # DNS 分流辅助
│   │           ├── i18n.lua                # 国际化
│   │           ├── haproxy.lua             # 负载均衡
│   │           ├── direct_ip              # 直连 IP 列表
│   │           ├── domains_excluded        # 排除域名列表
│   │           ├── tasks.sh                # 定时任务
│   │           ├── test.sh                 # 连通性测试
│   │           └── ...                     # 其他脚本
│   └── packages/                          # .apk 安装包
│       ├── luci-app-passwall2-*.apk        # PassWall2 LuCI 前端
│       ├── luci-i18n-passwall2-zh-cn-*.apk # 中文语言包
│       ├── xray-core-*.apk                 # Xray 代理核心
│       ├── sing-box-*.apk                  # sing-box 代理核心
│       ├── chinadns-ng-*.apk              # DNS 分流
│       ├── geoview-*.apk                   # GeoIP 查看工具
│       ├── hysteria-*.apk                 # Hysteria2 协议
│       ├── naiveproxy-*.apk               # NaiveProxy 协议
│       ├── shadowsocks-rust-sslocal-*.apk  # Shadowsocks 本地
│       ├── shadowsocks-rust-ssserver-*.apk # Shadowsocks 服务端
│       ├── shadowsocksr-libev-ssr-*.apk    # ShadowsocksR (local/redir/server)
│       ├── simple-obfs-client-*.apk        # Simple-OBFS 混淆
│       ├── tcping-*.apk                   # TCP 连通性测试
│       ├── v2ray-geoip-*.apk              # GeoIP 数据库
│       ├── v2ray-geosite-*.apk            # GeoSite 域名数据库
│       └── v2ray-plugin-*.apk             # WebSocket 传输插件
│
└── GL-SFT1200/                            # GL.iNet GL-SFT1200 (mipsel)
    └── README.md                           # 说明文档（此设备未安装 PassWall2）
```

## 文件用途

### rudy-TR3000/src/ — PassWall2 源码

从 Cudy TR3000 路由器（OpenWrt 25.12.4）上提取的 PassWall2 完整源码。

| 路径 | 用途 |
|------|------|
| `etc/init.d/passwall2` | PassWall2 主服务启动/停止脚本 |
| `etc/init.d/passwall2_server` | PassWall2 服务器端启动脚本 |
| `usr/lib/lua/luci/controller/passwall2.lua` | LuCI 菜单控制器 |
| `usr/lib/lua/luci/model/cbi/passwall2/` | LuCI 配置页面模型 |
| `usr/lib/lua/luci/view/passwall2/` | LuCI 视图模板 |
| `usr/lib/lua/luci/i18n/` | 多语言翻译文件 |
| `usr/share/passwall2/app.sh` | 主应用逻辑（生成配置、启动/停止代理） |
| `usr/share/passwall2/utils.sh` | 通用工具函数 |
| `usr/share/passwall2/iptables.sh` | iptables 防火墙规则管理 |
| `usr/share/passwall2/nftables.sh` | nftables 防火墙规则管理 |
| `usr/share/passwall2/monitor.sh` | 代理进程监控和自动恢复 |
| `usr/share/passwall2/subscribe.lua` | 节点订阅解析和更新 |
| `usr/share/passwall2/rule_update.lua` | GeoIP/GeoSite 规则更新 |
| `usr/share/passwall2/helper_dnsmasq.lua` | DNS 分流配置（dnsmasq + ChinaDNS-NG） |
| `usr/share/passwall2/i18n.lua` | 国际化支持模块 |
| `usr/share/passwall2/haproxy.lua` | 节点负载均衡 |
| `usr/share/passwall2/direct_ip` | 直连 IP 列表（不走代理的 IP 段） |
| `usr/share/passwall2/domains_excluded` | 排除域名列表（不走代理的域名） |
| `usr/share/passwall2/tasks.sh` | 定时任务（订阅更新、规则更新等） |
| `usr/share/passwall2/test.sh` | 节点连通性测试 |
| `usr/share/passwall2/0_default_config` | UCI 默认配置 |
| `usr/share/passwall2/socks_auto_switch.sh` | SOCKS 自动切换脚本 |
| `usr/share/passwall2/lease2hosts.sh` | DHCP 租约转 hosts 脚本 |
| `usr/share/passwall2/haproxy_check.sh` | HAProxy 健康检查脚本 |

### rudy-TR3000/packages/ — .apk 安装包

| 文件 | 版本 | 说明 |
|------|------|------|
| `luci-app-passwall2` | 26.9.16 | PassWall2 LuCI 前端 |
| `luci-i18n-passwall2-zh-cn` | 26.9.16 | 中文语言包 |
| `xray-core` | 26.3.27 | Xray 代理核心 |
| `sing-box` | 1.13.21 | sing-box 代理核心 |
| `chinadns-ng` | 2025.08.09 | ChinaDNS-NG DNS 分流 |
| `geoview` | 0.2.6 | GeoIP 查看/测试工具 |
| `hysteria` | 2.12.3 | Hysteria2 代理协议 |
| `naiveproxy` | 150.0.7871.63 | NaiveProxy 代理协议 |
| `shadowsocks-rust-sslocal` | 1.25.0 | Shadowsocks 本地客户端 |
| `shadowsocks-rust-ssserver` | 1.25.0 | Shadowsocks 服务端 |
| `shadowsocksr-libev-ssr-local` | 2.5.6 | ShadowsocksR 本地 |
| `shadowsocksr-libev-ssr-redir` | 2.5.6 | ShadowsocksR 透明代理 |
| `shadowsocksr-libev-ssr-server` | 2.5.6 | ShadowsocksR 服务端 |
| `simple-obfs-client` | 0.0.5 | Simple-OBFS 混淆插件 |
| `tcping` | 0.3 | TCP 连通性测试工具 |
| `v2ray-geoip` | 2026-07-17 | GeoIP 数据库 |
| `v2ray-geosite` | 2026-08-08 | GeoSite 域名数据库 |
| `v2ray-plugin` | 5.49.0 | WebSocket 传输插件 |

### rudy-TR3000/scripts/ — 安装脚本

| 文件 | 用途 |
|------|------|
| `install-passwall2.sh` | 一键完成：备份 → 校验 apk 完整性 → **一次性装齐 18 个包** → 部署 src → 清缓存启用 |

### GL-SFT1200/

此设备（GL.iNet GL-SFT1200, 116MB 内存）未安装 PassWall2。PassWall2 功能更复杂，建议在资源充裕的设备上使用。已安装的是 PassWall（非 PassWall2），详见 [passwall 仓库](https://github.com/sp431/passwall)。

## 安装方法

### Cudy TR3000 (rudy-TR3000)

推荐用一键脚本：

```bash
cd /tmp/rudy-TR3000 && sh scripts/install-passwall2.sh
```

手动安装时，**必须一条命令装齐全部包**（原因见下方「注意事项」）：

```bash
apk update
apk add luci-app-passwall2 luci-i18n-passwall2-zh-cn \
  xray-core sing-box chinadns-ng geoview hysteria naiveproxy \
  shadowsocks-rust-sslocal shadowsocks-rust-ssserver \
  shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir shadowsocksr-libev-ssr-server \
  simple-obfs-client tcping v2ray-geoip v2ray-geosite v2ray-plugin

# 或者完全离线安装（packages/ 中已包含全部 18 个包）
apk add --allow-untrusted packages/*.apk

# 部署源码 + 清缓存启用
cd src && tar -cf - etc usr | (cd / && tar -xf -)
chmod 755 /etc/init.d/passwall2 /etc/init.d/passwall2_server
rm -f /tmp/luci-indexcache* ; rm -rf /tmp/luci-modulecache
/etc/init.d/passwall2 enable
```

> **注意**：不要把上面的 `apk add` 拆成多条依次执行。任何一条失败都会在
> `/etc/apk/world` 留下未满足的约束，导致此后**所有 apk 命令报错**，
> 且 `apk del` 清不掉。

### 添加 PassWall2 软件源

如果 apk 仓库中找不到 PassWall2 包，需添加自定义源：

```bash
# 编辑 /etc/apk/repositories 添加：
# https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/aarch64_cortex-a53/passwall2/packages.adb
# https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-25.12/aarch64_cortex-a53/passwall_packages/packages.adb

# 更新并安装（源使用自签名证书，需 --allow-untrusted）
apk update --allow-untrusted
apk add --allow-untrusted luci-app-passwall2 luci-i18n-passwall2-zh-cn
```

> 实测：SourceForge 在部分网络下**只能读到索引文件**（几百字节），
> 包体（几十 KB 以上）连接会被中断。如果遇到这种情况，直接用本仓库
> `packages/` 离线安装即可，18 个包已齐全。

## 注意事项

- **批量安装必须一次装齐**：失败会在 `/etc/apk/world` 留下未满足的约束，导致此后所有
  apk 命令报错且 `apk del` 清不掉；修复需手工编辑 `/etc/apk/world` 并重新一次性安装
- **下载包要校验字节数**：并行后台下载容易截断（apk 报 `Connection aborted`），
  busybox 无 `stat`，用 `wc -c` 比对 GitHub 上的文件尺寸
- PassWall 和 PassWall2 可共存，但建议只启用其中一个
- PassWall2 共享 PassWall 的部分依赖包（xray-core, sing-box 等），与 passwall 仓库中的 packages 目录有重叠
- iptables 模块 `socket` 可能不可用，PassWall2 使用 nftables 替代
- 配置文件中不包含任何真实代理节点信息，请勿提交敏感数据
- SourceForge 软件源的包使用自签名证书，需 `--allow-untrusted` 选项