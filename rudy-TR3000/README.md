# PassWall2 - rudy-TR3000 (Cudy TR3000)

## 设备信息

| 项目 | 值 |
|------|-----|
| 型号 | Cudy TR3000 256MB v1 |
| 架构 | aarch64_cortex-a53 |
| 系统 | OpenWrt 25.12.4 (r32933-4ccb782af7)，定制固件 FanchmWrt |
| 目标 | mediatek/filogic |
| 内存 | 496MB |
| 包管理器 | **apk**（apk-tools 3.x，不是 opkg） |

## 已安装版本（2026-09-22 实测）

| 包名 | 版本 | 架构 |
|------|------|------|
| luci-app-passwall2 | 26.9.16-r1 | noarch |
| luci-i18n-passwall2-zh-cn | 26.9.16 | noarch |
| xray-core | 26.3.27-r1 | aarch64_cortex-a53 |
| sing-box | 1.13.21-r1 | aarch64_cortex-a53 |
| hysteria | 2.12.3-r1 | aarch64_cortex-a53 |
| geoview | 0.2.6-r1 | aarch64_cortex-a53 |
| chinadns-ng | 2025.08.09-r1 | aarch64_cortex-a53 |
| naiveproxy | 150.0.7871.63-r1 | aarch64_cortex-a53 |
| shadowsocks-rust-sslocal | 1.25.0-r1 | aarch64_cortex-a53 |
| shadowsocks-rust-ssserver | 1.25.0-r1 | aarch64_cortex-a53 |
| shadowsocksr-libev-ssr-local | 2.5.6-r12 | aarch64_cortex-a53 |
| shadowsocksr-libev-ssr-redir | 2.5.6-r12 | aarch64_cortex-a53 |
| shadowsocksr-libev-ssr-server | 2.5.6-r12 | aarch64_cortex-a53 |
| simple-obfs-client | 0.0.5-r3 | aarch64_cortex-a53 |
| tcping | 0.3-r1 | aarch64_cortex-a53 |
| v2ray-geoip | 202607171233-r1 | noarch |
| v2ray-geosite | 20260726062913-r1 | noarch |
| v2ray-plugin | 5.49.0-r1 | aarch64_cortex-a53 |

上述 18 个包在本仓库 `packages/` 中**全部齐全**，可完全离线安装。

实测运行状态：Xray 26.3.27 / sing-box 1.13.21 / Hysteria 2.12.3 / Geoview 0.2.6 均正常，
LuCI 菜单已注册，页面 `admin/services/passwall2` 返回 200。

## src/ 目录与设备路径的映射约定

与其他设备目录一致，`src/` 是路由器根文件系统的镜像：

| 仓库路径 | 设备路径 |
|----------|----------|
| `src/etc/` | `/etc/` |
| `src/usr/` | `/usr/` |

## 安装方法

### 方法 1：一键脚本（推荐）

```sh
cd /tmp/rudy-TR3000
sh scripts/install-passwall2.sh
```

脚本会串行校验并安装 `packages/` 中全部 18 个包，然后部署 `src/` 并清理缓存。
**必须用脚本或按下面"一次性装齐"的方式安装**，原因见踩坑记录第 1 条。

### 方法 2：手动一次性安装（关键：一条命令装齐）

```sh
apk update
apk add --allow-untrusted packages/*.apk
```

或者从在线源一条命令装齐：

```sh
apk add luci-app-passwall2 luci-i18n-passwall2-zh-cn \
  xray-core sing-box chinadns-ng geoview hysteria naiveproxy \
  shadowsocks-rust-sslocal shadowsocks-rust-ssserver \
  shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir shadowsocksr-libev-ssr-server \
  simple-obfs-client tcping v2ray-geoip v2ray-geosite v2ray-plugin
```

### 方法 3：部署 src/ 源码

```sh
cd src && tar -cf - etc usr | (cd / && tar -xf -)
chmod 755 /etc/init.d/passwall2 /etc/init.d/passwall2_server
rm -f /tmp/luci-indexcache* ; rm -rf /tmp/luci-modulecache
/etc/init.d/passwall2 enable
/etc/init.d/rpcd restart
```

## 验证安装

```sh
# 18 个包应全部出现在 apk 数据库
apk info -v | grep -E 'passwall2|xray-core|sing-box|hysteria|geoview'

# 核心版本
xray version | head -1
sing-box version | head -1
hysteria version | head -1

# 页面: http://<设备IP>/cgi-bin/luci/admin/services/passwall2
```

## 踩坑记录（实测）

### 1. 安装失败会在 `/etc/apk/world` 留下约束，导致 **apk 全面瘫痪**

如果一条 `apk add` 里有的包成功了、有的失败了，apk 会把**全部**包名写进
`/etc/apk/world`（包括失败的那些）。此后任何 apk 命令都会报：

```
world contains unresolved dependencies / unsatisfiable constraints
```

而且 `apk del` 清不掉这些残留条目。修复方式：手工编辑 `/etc/apk/world`
删掉未满足的行，然后**一次性**把所有相关包装齐（不能一个个装，单独装会因
其余包缺失而继续失败）。

### 2. 并行后台下载会把包下截断，引发"Connection aborted"

`apk add` 报 `Connection aborted` / 提取失败时，先怀疑包文件不完整。
实测踩过：`sing-box` 只下到 3.1MB（实际 12.9MB）、`xray-core` 差 90KB、
`hysteria` 只下一半。

排查方法（busybox **没有 `stat`**，用 `wc -c`）：

```sh
wc -c packages/sing-box-*.apk     # 与 GitHub 上文件尺寸比对
```

**结论：下载必须串行 + 逐个校验字节数，不要用并行后台任务。**

### 3. 安装顺序会影响结果

`luci-app-passwall2` 的依赖面很宽。先装核心包再装前端，或反过来，
都可能在中途失败并触发第 1 条的 world 污染。**最稳的是一条命令装齐。**

### 4. 与 PassWall 一代的关系

PassWall 与 PassWall2 共享同一批核心（xray-core / sing-box / hysteria 等），
两者可共存但**建议只启用其中一个** —— 同时启用会抢同一套 iptables/nftables 链。

## PassWall 与 PassWall2 的区别

| 特性 | PassWall | PassWall2 |
|------|----------|-----------|
| 配置方式 | 单一全局配置 | 分流配置（ACL） |
| DNS 处理 | 基础 DNS 分流 | 增强 DNS 分流 |
| 访问控制 | 基础 ACL | 高级 ACL（按源 IP 分流） |
| 订阅 | 支持订阅 | 支持订阅 + 转换 |
| 节点类型 | 基础类型 | 更多节点类型（含 Hysteria2, Naive） |
| 适用场景 | 简单代理需求 | 复杂分流需求 |

## 注意事项

- 此设备使用 apk 包管理器；busybox 无 `stat`，用 `wc -c` 查大小
- 全局开关默认关闭，装完需在页面中手动启用
- iptables 模块 `socket` 可能不可用，PassWall2 使用 nftables 替代
