# PassWall2 - rudy-TR3000 (Cudy TR3000)

## 设备信息
- 型号: Cudy TR3000 256MB v1
- 架构: aarch64_cortex-a53
- 系统: OpenWrt 25.12.4 (r32933-4ccb782af7)
- 目标: mediatek/filogic

## 已安装包

| 包名 | 版本 | 架构 |
|------|------|------|
| luci-app-passwall2 | 26.8.10-r1 | noarch |
| luci-i18n-passwall2-zh-cn | 26.8.10 | noarch |
| xray-core | 26.7.28-r1 | aarch64_cortex-a53 |
| sing-box | 1.13.18-r1 | aarch64_cortex-a53 |
| chinadns-ng | 2025.08.09-r1 | aarch64_cortex-a53 |
| geoview | 0.2.6-r1 | aarch64_cortex-a53 |
| hysteria | 2.12.1-r1 | aarch64_cortex-a53 |
| naiveproxy | 150.0.7871.63-r1 | aarch64_cortex-a53 |
| shadowsocks-rust-sslocal | 1.24.0-r1 | aarch64_cortex-a53 |
| shadowsocks-rust-ssserver | 1.24.0-r1 | aarch64_cortex-a53 |
| shadowsocksr-libev-ssr-local | 2.5.6-r12 | aarch64_cortex-a53 |
| shadowsocksr-libev-ssr-redir | 2.5.6-r12 | aarch64_cortex-a53 |
| shadowsocksr-libev-ssr-server | 2.5.6-r12 | aarch64_cortex-a53 |
| simple-obfs-client | 0.0.5-r3 | aarch64_cortex-a53 |
| tcping | 0.3-r1 | aarch64_cortex-a53 |
| v2ray-geoip | 202608060031.1 | noarch |
| v2ray-geosite | 202608082221.1 | noarch |
| v2ray-plugin | 5.49.0-r1 | aarch64_cortex-a53 |

## 安装方法

### 方法1: 通过 apk 安装（推荐）

```bash
# 添加 PassWall2 源
# 编辑 /etc/apk/repositories.d/customfeeds.list 添加：
# https://downloads.openwrt.org/releases/25.12.4/packages/aarch64_cortex-a53/passwall2/packages.adb
# https://downloads.openwrt.org/releases/25.12.4/packages/aarch64_cortex-a53/passwall_packages/packages.adb

apk update

# 安装 PassWall2
apk add luci-app-passwall2 luci-i18n-passwall2-zh-cn

# 安装代理核心和依赖
apk add xray-core sing-box chinadns-ng geoview hysteria naiveproxy \
  shadowsocks-rust-sslocal shadowsocks-rust-ssserver \
  shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir shadowsocksr-libev-ssr-server \
  simple-obfs-client tcping v2ray-geoip v2ray-geosite v2ray-plugin
```

### 方法2: 从本仓库安装

1. 将 `src/` 目录中的脚本和 Lua 文件复制到路由器对应路径
2. 将 `packages/` 中的二进制文件复制到 `/usr/bin/`

```bash
# 复制 PassWall2 脚本
cp -r src/usr/share/passwall2 /usr/share/passwall2

# 复制 LuCI 控制器
cp src/usr/lib/lua/luci/controller/passwall2.lua /usr/lib/lua/luci/controller/

# 复制 CBI 模型和视图
cp -r src/usr/lib/lua/luci/model/cbi/passwall2 /usr/lib/lua/luci/model/cbi/
cp -r src/usr/lib/lua/luci/view/passwall2 /usr/lib/lua/luci/view/

# 复制 init 脚本
cp src/etc/init.d/passwall2 /etc/init.d/passwall2
cp src/etc/init.d/passwall2_server /etc/init.d/passwall2_server
chmod +x /etc/init.d/passwall2 /etc/init.d/passwall2_server
/etc/init.d/passwall2 enable

# 复制二进制依赖
cp packages/usr/bin/xray /usr/bin/
cp packages/usr/bin/sing-box /usr/bin/
cp packages/usr/bin/chinadns-ng /usr/bin/
chmod +x /usr/bin/xray /usr/bin/sing-box /usr/bin/chinadns-ng
```

## 目录结构

```
src/
  usr/share/passwall2/    # PassWall2 核心脚本 (app.sh, utils.sh, etc.)
  etc/init.d/             # init 启动脚本
  usr/lib/lua/luci/       # LuCI 前端 (controller, model, view, i18n)
packages/
  usr/bin/                # 二进制依赖 (xray, sing-box, etc.)
  installed_packages.txt  # 完整已安装包列表
```

## PassWall 与 PassWall2 的区别

| 特性 | PassWall | PassWall2 |
|------|----------|-----------|
| 配置方式 | 单一全局配置 | 分流配置（ACL） |
| DNS 处理 | 基础 DNS 分流 | 增强 DNS 分流 |
| 访问控制 | 基础 ACL | 高级 ACL（按源 IP 分流） |
| 订阅 | 支持订阅 | 支持订阅+转换 |
| 节点类型 | 基础类型 | 更多节点类型（含 Hysteria2, Naive） |
| 适用场景 | 简单代理需求 | 复杂分流需求 |

## 注意事项

- 此设备使用 apk 包管理器
- PassWall 和 PassWall2 可共存，但建议只启用其中一个
- Xray-core v26.7.28 在此设备上运行正常
- iptables 模块 `socket` 可能不可用，PassWall2 使用 nftables 替代
