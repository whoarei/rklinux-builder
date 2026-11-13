# RKLinux Docker 构建环境

本目录用于提供一个 **Ubuntu 20.04** 容器环境，可完整编译本 RK3576 Linux SDK。

## 镜像

- 名称：`rklinux-builder`
- 基础镜像：`ubuntu:20.04`
- 包含：交叉工具链、内核/U-Boot 构建依赖、Debian rootfs 构建工具（debootstrap/qemu-user-static 等）、python2/python3 及常用模块。

## 获取镜像（推荐）

镜像由 GitHub Actions 自动构建并发布到 GHCR，直接拉取即可：

```bash
docker pull ghcr.io/whoarei/rklinux-builder:0.1.2
docker tag ghcr.io/whoarei/rklinux-builder:0.1.2 rklinux-builder
```

> 可用 `latest` 代替版本号获取最新镜像。

## 本地构建（备选）

仅在 GHCR 拉取困难（网络问题）或需要修改镜像时才本地构建：

```bash
docker build -t rklinux-builder .
```

> 如果网络较慢，可编辑 `Dockerfile` 里的镜像源，或者添加代理变量。

## 运行容器编译工程（映射整个工程）

进入工程根目录，然后启动容器：

```bash
docker run --rm -it --privileged \
    -v $PWD:$PWD \
    -e HOST_USER=$USER \
    -e HOST_UID=$(id -u) \
    -e HOST_GID=$(id -g) \
    -e HOST_PWD=$PWD \
    rklinux-builder
```

> `--privileged` 是必需的：入口脚本需要挂载 `binfmt_misc` 并启用
> `qemu-aarch64`，用于在 x86_64 上运行 arm64 二进制（debootstrap/live-build
> 构建 Debian rootfs 时依赖）。入口脚本已自动完成 binfmt 启用，无需手动操作。
>
> `HOST_*` 环境变量让入口脚本在容器内创建与宿主机同 UID/GID 的用户，
> 并以该用户执行命令，生成的文件在宿主机上仍归属当前用户；
> `HOST_PWD` 让入口脚本自动 `cd` 到挂载的工作目录，与 Dockerfile 的
> `WORKDIR` 无关。

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
    -v $PWD:$PWD \
    -e HOST_USER=$USER -e HOST_UID=$(id -u) -e HOST_GID=$(id -g) \
    -e HOST_PWD=$PWD \
    rklinux-builder ./build.sh
```

编译产物输出在 `output/` 与 `rockdev/` 中。

## 验证镜像

本地构建后运行以下检查；发布流程也会在推送镜像前执行：

```bash
bash tests/smoke.sh rklinux-builder
```

检查用户及文件属主、工作目录、免密 sudo、默认 Bash、错误输出和退出码、
缺少 gosu 时的备用分支，以及停止信号处理。

## 说明

- 本 SDK 需要 `python2`（部分 U-Boot/Rockchip 脚本依赖），容器内已安装 `python2`。
- 如果编译时报缺少某个包，可临时在容器里 `apt install` 并补充到 `Dockerfile` 中。
