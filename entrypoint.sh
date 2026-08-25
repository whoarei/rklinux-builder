#!/bin/bash
# rklinux-builder 容器入口脚本
# 1. 启用 qemu binfmt（Debian rootfs 构建需要在 x86_64 上运行 arm64 二进制）
# 2. 转交命令行（默认进入 bash）

set -e

# 需要 --privileged 才能操作 /proc/sys/fs/binfmt_misc
if [ -d /proc/sys/fs/binfmt_misc ]; then
    # 挂载 binfmt_misc（若内核未自动挂载）
    if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
        mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
    fi
    # 启用 qemu-aarch64 / qemu-arm（已注册则忽略警告）
    update-binfmts --enable qemu-aarch64 2>/dev/null || true
    update-binfmts --enable qemu-arm 2>/dev/null || true
fi

# 无参数时进入交互式 bash
if [ $# -eq 0 ]; then
    exec /bin/bash
fi

exec "$@"
