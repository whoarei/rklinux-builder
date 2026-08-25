# RKLinux Docker 构建环境

本目录用于提供一个 **Ubuntu 20.04** 容器环境，可完整编译本 RK3576 Linux SDK。

## 镜像

- 名称：`rklinux-builder`
- 基础镜像：`ubuntu:20.04`
- 包含：交叉工具链、内核/U-Boot 构建依赖、Debian rootfs 构建工具（debootstrap/qemu-user-static 等）、python2/python3 及常用模块。

## 构建镜像

```bash
docker build -t rklinux-builder -f docker/Dockerfile docker/
```

> 如果网络较慢，可编辑 `Dockerfile` 里的镜像源，或者添加代理变量。

## 运行容器（映射整个工程）

```bash
docker run --rm -it --privileged \
    -v /home/mmeng/rockchip/hzhy:/home/mmeng/rockchip/hzhy \
    rklinux-builder
```

> `--privileged` 是必需的：入口脚本需要挂载 `binfmt_misc` 并启用
> `qemu-aarch64`，用于在 x86_64 上运行 arm64 二进制（debootstrap/live-build
> 构建 Debian rootfs 时依赖）。入口脚本已自动完成 binfmt 启用，无需手动操作。

进入容器后执行：

```bash
# 首次使用：选择板级配置
./build.sh lunch

# 全编译
./build.sh
```

也可以直接在宿主机一条命令完成编译：

```bash
docker run --rm --privileged \
    -v /home/mmeng/rockchip/hzhy:/home/mmeng/rockchip/hzhy \
    rklinux-builder ./build.sh
```

编译产物输出在 `output/` 与 `rockdev/` 中。

## 说明

- 本 SDK 需要 `python2`（部分 U-Boot/Rockchip 脚本依赖），容器内已安装 `python2`。
- 如果编译时报缺少某个包，可临时在容器里 `apt install` 并补充到 `Dockerfile` 中。
