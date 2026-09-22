#!/bin/sh
# ============================================================
# PassWall2 一键安装脚本
# 目标设备: Cudy TR3000 256MB v1 / OpenWrt 25.12.4 (apk)
# 用法: cd /tmp/rudy-TR3000 && sh scripts/install-passwall2.sh
#
# 核心原则（踩坑总结）:
#   * 必须「一次性」装齐所有包 —— 否则 /etc/apk/world 会残留未满足的约束，
#     导致此后所有 apk 命令瘫痪，且 apk del 清不掉
#   * 安装前逐个校验 apk 文件非空 —— 截断的包会以 "Connection aborted" 报错
# ============================================================
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
PKG="$HERE/../packages"
SRC="$HERE/../src"

log() { echo "[passwall2] $*"; }
warn() { echo "[passwall2][WARN] $*" >&2; }

[ -x /sbin/apk ] || { echo "错误: 未检测到 apk，本脚本仅适用于 OpenWrt 25.x+"; exit 1; }
[ -d "$PKG" ] || { echo "错误: 找不到 packages 目录 $PKG"; exit 1; }

# ---------- 0. 备份 ----------
BAK="/root/_pw2_backup_$(date +%Y%m%d%H%M%S)"
log "0/5 备份到 $BAK"
mkdir -p "$BAK"
cp -f /etc/apk/world "$BAK"/world.bak 2>/dev/null
cp -f /etc/apk/repositories "$BAK"/repositories.bak 2>/dev/null
[ -f /etc/config/passwall2 ] && cp -f /etc/config/passwall2 "$BAK"/ 2>/dev/null
[ -d /usr/share/passwall2 ] && cp -r /usr/share/passwall2 "$BAK"/ 2>/dev/null

# ---------- 1. 校验包文件 ----------
log "1/5 校验 packages/ 中的 apk 文件"
N=0; BAD=0
for f in "$PKG"/*.apk; do
    [ -e "$f" ] || continue
    N=$((N+1))
    sz=$(wc -c < "$f" 2>/dev/null || echo 0)
    if [ "$sz" -lt 1024 ]; then
        warn "文件异常偏小（$(basename "$f") = ${sz} 字节），可能下载被截断"
        BAD=$((BAD+1))
    fi
done
log "    共 $N 个包，异常 $BAD 个"
[ "$N" -gt 0 ] || { echo "错误: packages/ 中没有 apk 文件"; exit 1; }
[ "$BAD" -eq 0 ] || warn "存在异常包，建议重新下载后再执行"

# ---------- 2. 更新索引 ----------
log "2/5 apk update"
apk update || warn "apk update 失败，请检查 /etc/apk/repositories"

# ---------- 3. 一次性装齐（关键步骤） ----------
log "3/5 一次性安装全部 $N 个包"
# shellcheck disable=SC2086
apk add --allow-untrusted "$PKG"/*.apk
RC=$?
if [ "$RC" -ne 0 ]; then
    warn "批量安装返回 $RC"
    warn "若提示 unsatisfiable constraints / unresolved dependencies，说明 /etc/apk/world"
    warn "被污染了。修复方式："
    warn "  1) 编辑 /etc/apk/world，删掉所有未满足的条目"
    warn "  2) 重新执行本脚本（必须一次性装齐）"
    warn "  3) 已安装的包会被 apk 自动跳过"
fi

# ---------- 4. 部署 src/ ----------
if [ -d "$SRC" ]; then
    log "4/5 部署 src/ -> /"
    cd "$SRC" || exit 1
    tar -cf - etc usr | (cd / && tar -xf -)
    chmod 755 /etc/init.d/passwall2 /etc/init.d/passwall2_server 2>/dev/null
    [ -d /usr/share/passwall2 ] && chmod 755 /usr/share/passwall2/*.sh 2>/dev/null
else
    log "4/5 跳过（无 src 目录，前端由 apk 提供）"
fi

# ---------- 5. 生效 ----------
log "5/5 清理 LuCI 缓存并启用服务"
rm -f /tmp/luci-indexcache* 2>/dev/null
rm -rf /tmp/luci-modulecache 2>/dev/null
/etc/init.d/passwall2 enable 2>/dev/null
/etc/init.d/rpcd restart 2>/dev/null

# 结果自检
log "自检：以下包应存在"
for p in luci-app-passwall2 xray-core sing-box hysteria geoview; do
    if grep -q "^$p$" /lib/apk/db/installed 2>/dev/null || \
       grep -q "^P:$p$" /lib/apk/db/installed 2>/dev/null; then
        log "    OK   $p"
    else
        warn "    缺失 $p"
    fi
done

log "安装完成。"
log "访问: http://<设备IP>/cgi-bin/luci/admin/services/passwall2"
log "注意: PassWall2 与 PassWall 共享核心，建议只启用其中一个。"
