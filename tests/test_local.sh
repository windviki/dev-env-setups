#!/bin/bash
# 本地单元测试
# 测试 setup.sh 的语法正确性、参数解析、模块选择逻辑

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PASS=0
FAIL=0

green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }

run_test() {
    local name="$1"
    local expected="$2"
    shift 2

    local result
    result=$("$@" 2>&1) || true

    if echo "$result" | grep -q "$expected"; then
        green "  PASS: $name"
        PASS=$((PASS + 1))
    else
        red "  FAIL: $name"
        red "    Expected to find: $expected"
        red "    Got: $result"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== dev-env-setups Unit Tests ==="
echo ""

cd "$PROJECT_DIR"

# Test 1: Help output
echo "[1] Help output tests"
run_test "help shows usage" "用法" bash setup.sh --help
run_test "help shows modules" "base" bash setup.sh --help
run_test "help shows --cn" "cn" bash setup.sh --help

# Test 2: Dry-run mode
echo ""
echo "[2] Dry-run tests"
run_test "dry-run all modules" "干运行" bash setup.sh --dry-run
run_test "dry-run with cn" "网络模式.*中国大陆" bash setup.sh --dry-run --cn
run_test "dry-run only uv" "开始安装模块.*uv" bash setup.sh --dry-run --only uv

# Test 3: Dockerfile generation
echo ""
echo "[3] Dockerfile generation tests"
run_test "docker flag generates dockerfile" "FROM ubuntu" bash setup.sh --cn --docker
run_test "docker with custom base image" "FROM debian:12" bash setup.sh --cn --docker --base-image debian:12
run_test "docker with only uv" "Modules: uv" bash setup.sh --docker --only uv

# Test 4: Mirror configuration
echo ""
echo "[4] Mirror config tests"
run_test "default github proxy" "gh.llkk.cc" bash -c 'source lib/mirrors.sh && echo $MIRROR_FOR_GITHUB'
run_test "default pypi index" "tuna.tsinghua" bash -c 'source lib/mirrors.sh && echo $MIRROR_PYPI_INDEX'
DOCKERFILE_CN=$(bash setup.sh --cn --docker --only base)
run_test "dockerfile contains mirror env" "MIRROR_FOR_GITHUB" echo "$DOCKERFILE_CN"

# Test 5: Module selection
echo ""
echo "[5] Module selection tests"
run_test "only single module" "开始安装模块.*uv" bash setup.sh --dry-run --only uv
run_test "only multiple modules" "开始安装模块.*nvm" bash setup.sh --dry-run --only "uv,nvm"
# Test that docker is removed when skipped
SKIP_OUT=$(bash setup.sh --dry-run --skip "docker,code-server" 2>&1 | grep "安装模块" || true)
if echo "$SKIP_OUT" | grep -qv "docker"; then
    green "  PASS: skip removes docker from module list"
    PASS=$((PASS + 1))
else
    red "  FAIL: skip should remove docker from module list"
    FAIL=$((FAIL + 1))
fi

# Test 6: Invalid module handling
echo ""
echo "[6] Error handling tests"
INVALID_OUT=$(bash setup.sh --only "nonexistent" 2>&1 | cat || true)
if echo "$INVALID_OUT" | grep -q "未知模块"; then
    green "  PASS: invalid module errors"
    PASS=$((PASS + 1))
else
    red "  FAIL: invalid module should error"
    red "    Got: $INVALID_OUT"
    FAIL=$((FAIL + 1))
fi

# Test 7: Shell syntax check
echo ""
echo "[7] Shell syntax checks"
if bash -n setup.sh 2>&1; then
    green "  PASS: setup.sh syntax valid"
    PASS=$((PASS + 1))
else
    red "  FAIL: setup.sh syntax invalid"
    FAIL=$((FAIL + 1))
fi
if bash -n lib/common.sh 2>&1; then
    green "  PASS: lib/common.sh syntax valid"
    PASS=$((PASS + 1))
else
    red "  FAIL: lib/common.sh syntax invalid"
    FAIL=$((FAIL + 1))
fi
if bash -n lib/mirrors.sh 2>&1; then
    green "  PASS: lib/mirrors.sh syntax valid"
    PASS=$((PASS + 1))
else
    red "  FAIL: lib/mirrors.sh syntax invalid"
    FAIL=$((FAIL + 1))
fi
if bash -n lib/modules.sh 2>&1; then
    green "  PASS: lib/modules.sh syntax valid"
    PASS=$((PASS + 1))
else
    red "  FAIL: lib/modules.sh syntax invalid"
    FAIL=$((FAIL + 1))
fi

# Summary
echo ""
echo "=== Test Results ==="
green "Passed: $PASS"
if [ "$FAIL" -gt 0 ]; then
    red "Failed: $FAIL"
    exit 1
else
    green "All tests passed!"
fi
