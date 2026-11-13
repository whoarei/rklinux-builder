#!/bin/bash
# rklinux-builder 容器入口脚本
# 1. 启用 qemu binfmt（Debian rootfs 构建需要在 x86_64 上运行 arm64 二进制）
# 2. 根据环境变量动态创建与宿主机一致的用户（避免生成 root 属主的文件）
# 3. cd 到宿主机挂载的工作目录，然后以该用户身份转交命令（默认进入 bash）

set -e

# ---------- 1. 启用 qemu binfmt（需要 --privileged） ----------
if [ -d /proc/sys/fs/binfmt_misc ]; then
    if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
        mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
    fi
    update-binfmts --enable qemu-aarch64 2>/dev/null || true
    update-binfmts --enable qemu-arm 2>/dev/null || true
fi

# ---------- 2. 动态创建与宿主机一致的用户 ----------
# 通过 -e HOST_USER=$USER -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) 传入
HOST_USER="${HOST_USER:-builder}"
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-$HOST_UID}"

if ! getent group "$HOST_GID" >/dev/null 2>&1; then
    groupadd -g "$HOST_GID" "$HOST_USER"
fi
if ! getent passwd "$HOST_UID" >/dev/null 2>&1; then
    useradd -u "$HOST_UID" -g "$HOST_GID" -m -s /bin/bash "$HOST_USER" 2>/dev/null \
        || useradd -u "$HOST_UID" -g "$HOST_GID" -M -s /bin/bash "$HOST_USER"
fi
echo "$HOST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hostuser

# ---------- 3. 切换到宿主机工作目录 ----------
# 通过 -e HOST_PWD=$PWD 传入；目录在容器内存在（即已挂载）才切换
if [ -n "$HOST_PWD" ] && [ -d "$HOST_PWD" ]; then
    cd "$HOST_PWD"
fi

# ---------- 4. 以目标用户身份转交命令 ----------
if [ $# -eq 0 ]; then
    set -- /bin/bash
fi

if [ "$(id -u)" = "0" ]; then
    # 非交互 Bash 中 exec 找不到命令会直接退出，必须先检查再选择备用方式。
    # 保留标准错误，避免隐藏切换用户或目标命令的报错。
    if command -v gosu >/dev/null 2>&1; then
        exec gosu "$HOST_USER" "$@"
    else
        exec runuser -u "$HOST_USER" -- "$@"
    fi
else
    exec "$@"
fi
