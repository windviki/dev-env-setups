#!/bin/bash
# Docker 完整镜像构建 + 模块级耗时评估
# 记录每个模块的耗时和总构建时间
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${PROJECT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/docker-build-timed-${TIMESTAMP}.log"
IMAGE_NAME="dev-env-full:${TIMESTAMP}"

mkdir -p "$LOG_DIR"

echo "=== dev-env-setups Full Docker Build (Timed) ==="
echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Log: ${LOG_FILE}"
echo ""

# 记录总开始时间
START_TOTAL=$(date +%s)

# 构建并记录每行时间戳
cd "$PROJECT_DIR"
docker build \
    --progress=plain \
    -t "${IMAGE_NAME}" \
    -f docker/Dockerfile.full \
    . 2>&1 | while IFS= read -r line; do
    echo "[$(date +%H:%M:%S)] $line"
done | tee "$LOG_FILE"

# 记录总结束时间
END_TOTAL=$(date +%s)
ELAPSED=$((END_TOTAL - START_TOTAL))

echo ""
echo "============================================"
echo "构建完成！总耗时: ${ELAPSED}秒 ($((ELAPSED / 60))分$((ELAPSED % 60))秒)"
echo "镜像: ${IMAGE_NAME}"
echo "日志: ${LOG_FILE}"
echo "============================================"

# 从日志中提取各模块耗时估算
echo ""
echo "=== 模块耗时分析 ==="

analyze_module() {
    local module="$1"
    local label="$2"
    local start_ts end_ts

    # 查找模块开始和下一个模块开始之间的时间
    start_ts=$(grep "开始安装模块.*${module}" "$LOG_FILE" 2>/dev/null | head -1 | sed 's/^\[\(.*\)\].*/\1/' || true)

    if [ -z "$start_ts" ]; then
        echo "  ${label}: 未找到开始标记"
        return
    fi

    # 提取时:分:秒转为秒数
    local start_sec=$(echo "$start_ts" | awk -F: '{print $1*3600 + $2*60 + $3}')

    # 找下一个事件的时间戳
    local next_line
    next_line=$(grep -n "开始安装模块.*${module}" "$LOG_FILE" 2>/dev/null | head -1 | cut -d: -f1 || true)

    # 获取之后所有行中找到下一个模块的时间
    local end_sec=0
    if [ -n "$next_line" ]; then
        # 尝试找下一个模块的开始
        local next_ts
        next_ts=$(tail -n +$((next_line + 1)) "$LOG_FILE" 2>/dev/null | grep -m1 "开始安装模块\|所有模块安装完成\|Install Modules\|Environment Setup" | sed 's/^\[\(.*\)\].*/\1/' || true)
        if [ -n "$next_ts" ]; then
            end_sec=$(echo "$next_ts" | awk -F: '{print $1*3600 + $2*60 + $3}')
        fi
    fi

    if [ "$end_sec" -gt "$start_sec" ] 2>/dev/null; then
        local diff=$((end_sec - start_sec))
        echo "  ${label}: ${diff}秒 ($((diff / 60))分$((diff % 60))秒)"
    else
        echo "  ${label}: 开始于 ${start_ts} (无法确定结束时间)"
    fi
}

echo "各模块安装时间（从构建日志提取）:"
echo "  注: 模块在同一个RUN层中顺序执行，时间包含apt/编译/下载等"
echo ""

for mod_pair in "base:基础依赖" "docker:Docker CE" "uv:Python/uv" "nvm:Node.js" "rustup:Rust" "gvm:Go" "sdkman:Java" "code-server:code-server" "chsrc:chsrc" "xcmd:x-cmd"; do
    mod="${mod_pair%%:*}"
    label="${mod_pair##*:}"
    analyze_module "$mod" "${label}"
done

echo ""
echo "=== 构建验证 ==="
echo "检查容器内各工具版本..."

docker run --rm "${IMAGE_NAME}" bash -c '
echo "--- 系统信息 ---"
cat /etc/os-release | head -n 2

echo ""
echo "--- 已安装工具 ---"
for tool in uv node rustc go java code-server chsrc; do
    if command -v $tool &>/dev/null; then
        printf "  %-15s: %s\n" "$tool" "$($tool --version 2>&1 | head -1 | tr "\n" " ")"
    else
        printf "  %-15s: NOT FOUND\n" "$tool"
    fi
done

echo ""
echo "--- x-cmd ---"
[ -d /root/.x-cmd.root ] && echo "  x-cmd: installed" || echo "  x-cmd: NOT FOUND"
' 2>&1

echo ""
echo "============================================"
echo "测试完成"
echo "清理镜像: docker rmi ${IMAGE_NAME}"
