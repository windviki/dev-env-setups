#!/bin/bash
# Docker 环境集成测试
# 在 Docker 容器中启动 ubuntu:22.04，执行完整安装流程，验证所有模块

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${PROJECT_DIR}/logs"
IMAGE_NAME="dev-env-test:$(date +%Y%m%d%H%M%S)"

mkdir -p "$LOG_DIR"

echo "=== dev-env-setups Docker Integration Test ==="
echo "Project: ${PROJECT_DIR}"
echo "Logs: ${LOG_DIR}"
echo ""

# Step 1: Generate Dockerfile from setup.sh
echo "[1/3] Generating Dockerfile..."
cd "$PROJECT_DIR"
bash setup.sh --cn --docker --base-image ubuntu:22.04 > "${LOG_DIR}/Dockerfile.generated"
echo "  Dockerfile saved to logs/Dockerfile.generated"

# Step 2: Build Docker image
echo "[2/3] Building Docker image: ${IMAGE_NAME}..."
docker build \
    --progress=plain \
    -t "${IMAGE_NAME}" \
    -f "${LOG_DIR}/Dockerfile.generated" \
    "$PROJECT_DIR" 2>&1 | tee "${LOG_DIR}/docker-build-$(date +%Y%m%d).log"

echo ""
echo "[3/3] Running verification tests..."

# Step 3: Run verification commands in container
docker run --rm "${IMAGE_NAME}" bash -c '
set -e

echo "=== Verification Report ==="
echo ""

# OS info
echo "--- OS Info ---"
cat /etc/os-release | head -n 3
echo ""

# Python / uv
echo "--- Python ---"
if command -v uv &>/dev/null; then
    echo "  uv: $(uv --version 2>/dev/null || echo installed)"
    echo "  python: $(uv python list 2>/dev/null | head -3 || echo check manual)"
else
    echo "  uv: NOT FOUND"
fi
echo ""

# Node.js
echo "--- Node.js ---"
if [ -d /root/.nvm ]; then
    echo "  nvm: installed"
    export NVM_DIR="/root/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    if command -v node &>/dev/null; then
        echo "  node: $(node --version)"
        echo "  npm:  $(npm --version)"
    fi
else
    echo "  nvm: NOT FOUND"
fi
echo ""

# Rust
echo "--- Rust ---"
if command -v rustc &>/dev/null; then
    echo "  rustc: $(rustc --version)"
    echo "  cargo: $(cargo --version)"
elif [ -d /root/.cargo ]; then
    echo "  cargo: installed (may need source)"
else
    echo "  rust: NOT FOUND"
fi
echo ""

# Go
echo "--- Go ---"
if [ -d /root/.gvm ]; then
    echo "  gvm: installed"
    if [ -d /root/.gvm/gos/go1.24.13 ]; then
        echo "  go: 1.24.13 (binary installed)"
    fi
else
    echo "  gvm: NOT FOUND"
fi
echo ""

# Java
echo "--- Java ---"
if [ -d /root/.sdkman ]; then
    echo "  sdkman: installed"
    if [ -d /root/.sdkman/candidates/java ]; then
        ls /root/.sdkman/candidates/java/ 2>/dev/null | head -3 || echo "  (no JDK yet)"
    fi
else
    echo "  sdkman: NOT FOUND"
fi
echo ""

# code-server
echo "--- code-server ---"
if command -v code-server &>/dev/null; then
    echo "  code-server: $(code-server --version 2>/dev/null || echo installed)"
else
    echo "  code-server: NOT FOUND"
fi
echo ""

# chsrc
echo "--- chsrc ---"
if command -v chsrc &>/dev/null; then
    echo "  chsrc: installed"
else
    echo "  chsrc: NOT FOUND"
fi
echo ""

# x-cmd
echo "--- x-cmd ---"
if [ -d /root/.x-cmd.root ]; then
    echo "  x-cmd: installed"
else
    echo "  x-cmd: NOT FOUND"
fi
echo ""

echo "=== Verification Complete ==="
' 2>&1 | tee "${LOG_DIR}/verification-$(date +%Y%m%d).log"

echo ""
echo "=== Docker test complete ==="
echo "Full logs: ${LOG_DIR}/"
echo ""
echo "To inspect the image manually:"
echo "  docker run -it ${IMAGE_NAME} bash"
echo ""
echo "To clean up:"
echo "  docker rmi ${IMAGE_NAME}"
