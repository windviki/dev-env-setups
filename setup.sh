#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_TMPDIR="/tmp/dev-env-setups"

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/mirrors.sh"
source "${SCRIPT_DIR}/lib/modules.sh"

VERSION="1.0.0"
BASE_IMAGE="${BASE_IMAGE:-ubuntu:22.04}"
USE_CN="false"
ONLY_MODULES=""
SKIP_MODULES=""
GENERATE_DOCKERFILE="false"
DRY_RUN="false"

usage() {
    cat <<EOF
dev-env-setups v${VERSION} - 一键开发环境搭建脚本

用法: setup.sh [选项]

模块选择:
  --only MODULES       只安装指定模块（逗号分隔）
  --skip MODULES       跳过指定模块（逗号分隔）
  可选模块: $(IFS=,; echo "${ALL_MODULES[*]}")

国内镜像:
  --cn                 启用中国大陆网络环境镜像加速
  --cn-github-proxy URL        覆盖 GitHub 代理地址（默认: ${MIRROR_FOR_GITHUB}）
  --cn-apt-source URL          覆盖 APT 源地址（默认: ${MIRROR_APT_SOURCE}）
  --cn-docker-mirror NAME      覆盖 Docker 镜像（默认: ${MIRROR_DOCKER}）
  --cn-pypi-index URL          覆盖 PyPI 镜像（默认: ${MIRROR_PYPI_INDEX}）
  --cn-npm-registry URL        覆盖 npm 镜像（默认: ${MIRROR_NPM_REGISTRY}）
  --cn-node-mirror URL         覆盖 Node.js 镜像（默认: ${MIRROR_NODE}）
  --cn-rustup-dist URL         覆盖 Rustup 分发服务器（默认: ${MIRROR_RUSTUP_DIST}）
  --cn-rustup-update URL       覆盖 Rustup 更新服务器（默认: ${MIRROR_RUSTUP_UPDATE}）
  --cn-cargo-registry NAME     覆盖 Cargo 镜像（默认: ${MIRROR_CARGO_REGISTRY}）
  --cn-go-proxy URL            覆盖 Go 代理（默认: ${MIRROR_GO_PROXY}）
  --cn-go-binary URL           覆盖 Go 二进制下载（默认: ${MIRROR_GO_BINARY}）

安装模式:
  --docker              生成 Dockerfile 而非本地安装
  --base-image IMAGE    指定 Docker 基础镜像（默认: ${BASE_IMAGE}）

其他:
  --dry-run             仅打印将要执行的操作，不实际安装
  -h, --help            显示此帮助信息

示例:
  # 本地全部安装（国内网络环境）
  ./setup.sh --cn

  # 只安装 Python 和 Node.js 环境，使用国内镜像
  ./setup.sh --cn --only uv,nvm

  # 安装全部但跳过 Docker
  ./setup.sh --skip docker

  # 生成 Dockerfile 用于构建开发环境镜像
  ./setup.sh --cn --docker > Dockerfile

  # 指定基础镜像生成 Dockerfile
  ./setup.sh --cn --docker --base-image debian:12 > Dockerfile
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --only)
                ONLY_MODULES="$2"; shift ;;
            --skip)
                SKIP_MODULES="$2"; shift ;;
            --cn)
                USE_CN="true" ;;
            --cn-github-proxy)
                MIRROR_FOR_GITHUB="$2"; shift ;;
            --cn-apt-source)
                MIRROR_APT_SOURCE="$2"; shift ;;
            --cn-docker-mirror)
                MIRROR_DOCKER="$2"; shift ;;
            --cn-pypi-index)
                MIRROR_PYPI_INDEX="$2"; shift ;;
            --cn-npm-registry)
                MIRROR_NPM_REGISTRY="$2"; shift ;;
            --cn-node-mirror)
                MIRROR_NODE="$2"; shift ;;
            --cn-rustup-dist)
                MIRROR_RUSTUP_DIST="$2"; shift ;;
            --cn-rustup-update)
                MIRROR_RUSTUP_UPDATE="$2"; shift ;;
            --cn-cargo-registry)
                MIRROR_CARGO_REGISTRY="$2"; shift ;;
            --cn-go-proxy)
                MIRROR_GO_PROXY="$2"; shift ;;
            --cn-go-binary)
                MIRROR_GO_BINARY="$2"; shift ;;
            --docker)
                GENERATE_DOCKERFILE="true" ;;
            --base-image)
                BASE_IMAGE="$2"; shift ;;
            --dry-run)
                DRY_RUN="true" ;;
            -h|--help)
                usage; exit 0 ;;
            *)
                log_error "未知选项: $1"
                echo "使用 --help 查看帮助"
                exit 1 ;;
        esac
        shift
    done
}

resolve_modules() {
    local selected=()

    if [ -n "$ONLY_MODULES" ]; then
        IFS=',' read -ra names <<< "$ONLY_MODULES"
        for name in "${names[@]}"; do
            name="$(echo "$name" | xargs)"
            local found=false
            for m in "${ALL_MODULES[@]}"; do
                if [ "$m" = "$name" ]; then found=true; break; fi
            done
            if [ "$found" = "true" ]; then
                selected+=("$name")
            else
                log_error "未知模块: $name"
                log_info "可用模块: ${ALL_MODULES[*]}"
                exit 1
            fi
        done
    else
        selected=("${ALL_MODULES[@]}")
    fi

    if [ -n "$SKIP_MODULES" ]; then
        IFS=',' read -ra skip_names <<< "$SKIP_MODULES"
        local filtered=()
        for m in "${selected[@]}"; do
            local skip=false
            for s in "${skip_names[@]}"; do
                s="$(echo "$s" | xargs)"
                if [ "$m" = "$s" ]; then skip=true; break; fi
            done
            if [ "$skip" = "false" ]; then
                filtered+=("$m")
            fi
        done
        selected=("${filtered[@]}")
    fi

    echo "${selected[@]}"
}

run_install() {
    local module="$1"
    local use_cn="$2"

    case "$module" in
        base)        install_base "$use_cn" ;;
        docker)      install_docker "$use_cn" ;;
        uv)          install_uv "$use_cn" ;;
        nvm)         install_nvm "$use_cn" ;;
        rustup)      install_rustup "$use_cn" ;;
        gvm)         install_gvm "$use_cn" ;;
        sdkman)      install_sdkman "$use_cn" ;;
        code-server) install_code_server "$use_cn" ;;
        chsrc)       install_chsrc "$use_cn" ;;
        xcmd)        install_xcmd "$use_cn" ;;
    esac
}

local_install() {
    local modules=("$@")

    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║     dev-env-setups v${VERSION} - 开发环境安装    ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${PLAIN}"

    log_info "操作系统: $(detect_os) $(detect_os_version)"
    log_info "安装模块: ${modules[*]}"
    if [ "$USE_CN" = "true" ]; then
        log_info "网络模式: 中国大陆（镜像加速）"
    else
        log_info "网络模式: 国际网络"
    fi
    echo ""

    mkdir -p "$INSTALL_TMPDIR"

    for module in "${modules[@]}"; do
        echo ""
        echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
        log_info "开始安装模块: ${BOLD}$module${PLAIN}"
        echo ""

        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY-RUN] 将执行: install_${module}"
        else
            if ! run_install "$module" "$USE_CN"; then
                log_error "模块 $module 安装失败，继续安装后续模块..."
            fi
        fi
    done

    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║          所有模块安装完成！                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${PLAIN}"

    if [ "$USE_CN" = "true" ]; then
        echo ""
        log_info "镜像环境变量已写入 ~/.bashrc 和 ~/.profile"
        echo ""
    fi
}

generate_dockerfile() {
    local modules=("$@")

    local module_array=""
    for m in "${modules[@]}"; do
        module_array="${module_array} ${m}"
    done

    cat <<DOCKERFILE_HEADER
# =============================================================================
# Dockerfile generated by dev-env-setups v${VERSION}
# Generated at: $(date '+%Y-%m-%d %H:%M:%S')
# Modules:${module_array}
# Base Image: ${BASE_IMAGE}
# China Mirror: ${USE_CN}
# =============================================================================

FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \\
    TZ=Asia/Shanghai

RUN set -eux; \\
    apt-get update -qq && \\
    apt-get install -y -qq --no-install-recommends \\
        ca-certificates curl wget git vim \\
        zip unzip build-essential gcc make cmake \\
        net-tools iputils-ping telnet \\
        pkg-config autoconf automake g++ \\
        libssl-dev libexpat1-dev libpcre3-dev \\
        libcap-dev bison flex && \\
    rm -rf /var/lib/apt/lists/*

# Copy the setup scripts into the image
COPY . /opt/dev-env-setups
WORKDIR /opt/dev-env-setups

DOCKERFILE_HEADER

    if [ "$USE_CN" = "true" ]; then
        cat <<DOCKERFILE_CN

# ---------- China Mirror Environment Variables ----------
ENV MIRROR_FOR_GITHUB=${MIRROR_FOR_GITHUB} \\
    MIRROR_APT_SOURCE=${MIRROR_APT_SOURCE} \\
    MIRROR_DOCKER=${MIRROR_DOCKER} \\
    MIRROR_PYPI_INDEX=${MIRROR_PYPI_INDEX} \\
    MIRROR_NPM_REGISTRY=${MIRROR_NPM_REGISTRY} \\
    MIRROR_NODE=${MIRROR_NODE} \\
    MIRROR_RUSTUP_DIST=${MIRROR_RUSTUP_DIST} \\
    MIRROR_RUSTUP_UPDATE=${MIRROR_RUSTUP_UPDATE} \\
    MIRROR_CARGO_REGISTRY=${MIRROR_CARGO_REGISTRY} \\
    MIRROR_GO_PROXY=${MIRROR_GO_PROXY} \\
    MIRROR_GO_BINARY=${MIRROR_GO_BINARY}
DOCKERFILE_CN
    fi

    local cn_flag=""
    if [ "$USE_CN" = "true" ]; then
        cn_flag="--cn"
    fi

    local modules_str
    modules_str=$(IFS=,; echo "${modules[*]}")

    cat <<DOCKERFILE_RUN

# ---------- Install Modules ----------
RUN bash setup.sh ${cn_flag} --only "${modules_str}"

# ---------- Environment Setup ----------
ENV PATH="/root/.local/bin:/root/.nvm/versions/node/\$(node --version 2>/dev/null || echo v22)/bin:/root/.cargo/bin:/root/.gvm/gos/go1.24.13/bin:/root/.sdkman/candidates/java/current/bin:\$PATH"

# ---------- Cleanup ----------
RUN rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /workspace
CMD ["/bin/bash"]
DOCKERFILE_RUN
}

main() {
    parse_args "$@"

    if [ "$DRY_RUN" = "true" ]; then
        log_info "=== 干运行模式 ==="
    fi

    local selected_modules
    selected_modules=($(resolve_modules))

    if [ ${#selected_modules[@]} -eq 0 ]; then
        log_error "没有选中任何模块，请检查 --only/--skip 参数"
        exit 1
    fi

    if [ "$GENERATE_DOCKERFILE" = "true" ]; then
        generate_dockerfile "${selected_modules[@]}"
    else
        local_install "${selected_modules[@]}"
    fi
}

main "$@"
