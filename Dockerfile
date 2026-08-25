FROM ubuntu:20.04

# 非交互模式 + 时区
ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Shanghai

# 使用国内镜像加速（USTC），同时更新 locale 避免编译时的编码警告
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirrors.ustc.edu.cn/ubuntu|g; \
            s|http://security.ubuntu.com/ubuntu|http://mirrors.ustc.edu.cn/ubuntu|g' \
            /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales tzdata ca-certificates \
    && locale-gen en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# 基础构建依赖（kernel/u-boot/rootfs/通用工具）
RUN apt-get install -y --no-install-recommends \
    build-essential gcc g++ make cmake ninja-build \
    crossbuild-essential-arm64 gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    bc bison flex libssl-dev libncurses5-dev libncursesw5-dev \
    libgmp-dev libmpc-dev \
    device-tree-compiler u-boot-tools \
    python3 python3-dev python3-pip python3-setuptools python3-wheel \
    python-is-python3 \
    git git-core curl wget rsync unzip file \
    kmod cpio lz4 lzop xz-utils zstd \
    liblz4-tool lz4 \
    mtd-utils \
    parted fdisk gdisk dosfstools e2fsprogs \
    fakeroot debootstrap qemu-user-static binfmt-support \
    swig libgnutls28-dev libfdt-dev libglib2.0-dev libpixman-1-dev \
    libjson-c-dev liblzma-dev \
    mtools squashfs-tools \
    gawk sed grep diffutils patch findutils \
    texinfo autopoint gettext \
    python3-mako \
    expect expect-dev \
    net-tools iputils-ping sudo vim less \
    bsdmainutils \
    && rm -rf /var/lib/apt/lists/*

# live-build / debootstrap 需要支持 Debian bookworm（focal 自带版本过旧），
# 按 SDK check-debian.sh 提示从 salsa.debian.org 源码安装
RUN git clone https://salsa.debian.org/live-team/live-build.git --depth 1 -b debian/1%20230131 /tmp/live-build \
    && cd /tmp/live-build \
    && rm -rf manpages/po/ \
    && make install -j"$(nproc)" \
    && cd / && rm -rf /tmp/live-build

RUN git clone https://salsa.debian.org/installer-team/debootstrap.git --depth 1 -b debian/1.0.123+deb11u2 /tmp/debootstrap \
    && cd /tmp/debootstrap \
    && make install -j"$(nproc)" \
    && cd / && rm -rf /tmp/debootstrap

# e2fsprogs 需要 v1.46.6（focal 自带 1.45 缺少 ext2fs_truncate_orphan_file 符号，
# 且 -d 选项和 metadata_csum_seed/orphan_file 特性支持不完整）
RUN git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git --depth 1 -b v1.46.6 /tmp/e2fsprogs \
    && cd /tmp/e2fsprogs \
    && ./configure \
    && make install -j"$(nproc)" -k -i \
    && cd / && rm -rf /tmp/e2fsprogs \
    && ldconfig

# python2.7 是部分 Rockchip 脚本（如 boot loader 相关）需要的
# Ubuntu 20.04 官方源仍有 python2.7，优先使用
RUN apt-get update \
    && apt-get install -y --no-install-recommends python2 python2-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 模块（U-Boot 与 Rockchip 脚本常用）
RUN pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple \
    pyelftools pylibfdt setuptools && \
    if command -v pip2 >/dev/null 2>&1; then \
        pip2 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple pyelftools; \
    fi

# 常用环境变量，避免 perl 警告
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# 创建与宿主机一致的普通用户（SDK 构建脚本内部会 sudo 到该用户）
RUN groupadd -g 1000 mmeng \
    && useradd -u 1000 -g 1000 -m -s /bin/bash mmeng \
    && echo "mmeng ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/mmeng \
    && echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/mmeng

# 工作目录（对应宿主机挂载点）
WORKDIR /home/mmeng/rockchip/hzhy

# 入口脚本：自动启用 qemu binfmt，然后转交命令
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# 默认进入 bash
CMD []
