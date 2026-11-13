#!/bin/bash
# 在真实容器中验证入口脚本；需要 Docker 及启动特权容器的权限。
set -euo pipefail

IMAGE="${1:-rklinux-builder}"
WORKSPACE=$(mktemp -d)
SIGNAL_CONTAINER="rklinux-builder-smoke-$$"

# 信号检查使用后台容器，失败时也必须清理容器和挂载目录。
cleanup() {
    docker rm -f "$SIGNAL_CONTAINER" >/dev/null 2>&1 || true
    rm -rf "$WORKSPACE"
}
trap cleanup EXIT

ARGS=(--privileged
    --mount "type=bind,source=$WORKSPACE,target=$WORKSPACE"
    --env "HOST_USER=$(id -un)"
    --env "HOST_UID=$(id -u)"
    --env "HOST_GID=$(id -g)"
    --env "HOST_PWD=$WORKSPACE")

docker run --rm "${ARGS[@]}" "$IMAGE" /bin/bash -ec '
    command -v gosu
    test "$(id -u)" = "$HOST_UID"
    test "$(id -g)" = "$HOST_GID"
    test "$PWD" = "$HOST_PWD"
    test "$(sudo -n id -u)" = 0
    test "$$" = 1
    touch artifact
'
test "$(stat -c %u "$WORKSPACE/artifact")" = "$(id -u)"
test "$(stat -c %g "$WORKSPACE/artifact")" = "$(id -g)"
echo 'PASS: gosu, user/group, workdir, sudo, file ownership and process replacement'

# 不传命令，确认入口仍默认启动 Bash 并接受标准输入。
printf '%s\n' 'test "$(id -u)" = "$HOST_UID" && printf default-bash-ok' |
    docker run --rm --interactive "${ARGS[@]}" "$IMAGE" > "$WORKSPACE/default.out"
test "$(cat "$WORKSPACE/default.out")" = default-bash-ok
echo 'PASS: default Bash'

STATUS=0
docker run --rm "${ARGS[@]}" "$IMAGE" /bin/bash -c \
    'echo smoke-error >&2; exit 42' > "$WORKSPACE/command.out" 2> "$WORKSPACE/command.err" || STATUS=$?
test "$STATUS" = 42
grep -qx smoke-error "$WORKSPACE/command.err"
echo 'PASS: stderr and exit status'

# 只删除临时容器内的 gosu，覆盖发布故障涉及的缺失依赖场景。
docker run --rm "${ARGS[@]}" --entrypoint /bin/bash "$IMAGE" -ec '
    rm "$(command -v gosu)"
    exec /usr/local/bin/entrypoint.sh /bin/bash -ec '\''
        test "$(id -u)" = "$HOST_UID"
        test "$PWD" = "$HOST_PWD"
        test "$(sudo -n id -u)" = 0
    '\''
'
echo 'PASS: runuser fallback without gosu'

# 等待目标进程装好 TERM 处理器，避免启动和停止之间的竞争。
docker run --detach --name "$SIGNAL_CONTAINER" "${ARGS[@]}" "$IMAGE" /bin/bash -c \
    'trap "exit 0" TERM; echo ready; while :; do sleep 0.1; done' >/dev/null
READY=false
for ((attempt = 0; attempt < 50; attempt++)); do
    if docker logs "$SIGNAL_CONTAINER" | grep -qx ready; then
        READY=true
        break
    fi
    sleep 0.1
done
test "$READY" = true
docker stop --time 5 "$SIGNAL_CONTAINER" >/dev/null
test "$(docker inspect --format '{{.State.ExitCode}}' "$SIGNAL_CONTAINER")" = 0
echo 'PASS: SIGTERM reaches the target process'
