#!/bin/bash
# Module definitions and installation functions for dev-env-setups

ALL_MODULES=(
    "base"
    "docker"
    "uv"
    "nvm"
    "rustup"
    "gvm"
    "sdkman"
    "code-server"
    "chsrc"
    "xcmd"
)

MODULE_DESC=(
    "base:系统基础依赖和apt源替换（linuxmirrors）"
    "docker:Docker CE 容器引擎"
    "uv:Python包管理器 + Python 3.11.14"
    "nvm:Node.js版本管理器 + Node.js LTS + npm全局包"
    "rustup:Rust工具链管理器 + stable工具链"
    "gvm:Go版本管理器 + Go 1.24.13"
    "sdkman:JDK版本管理器 + Java 25.0.2-ms"
    "code-server:VS Code Web服务端"
    "chsrc:全平台换源工具"
    "xcmd:x-cmd Shell工具集合"
)

INSTALL_TMPDIR="/tmp/dev-env-setups"

# ============================================================================
# Module: base - System base dependencies + apt source mirror
# ============================================================================
install_base() {
    local use_cn="${1:-false}"

    log_step "安装系统基础依赖..."

    if [ "$use_cn" = "true" ]; then
        log_info "配置国内APT源镜像: ${MIRROR_APT_SOURCE}"
        curl -sSL https://linuxmirrors.cn/main.sh -o "${INSTALL_TMPDIR}/install_linuxmirrors.sh"
        chmod +x "${INSTALL_TMPDIR}/install_linuxmirrors.sh"
        sudo_cmd bash "${INSTALL_TMPDIR}/install_linuxmirrors.sh" \
            --source "${MIRROR_APT_SOURCE}" \
            --protocol http \
            --use-intranet-source false \
            --install-epel true \
            --backup true \
            --upgrade-software false \
            --clean-cache false \
            --ignore-backup-tips || log_warn "linuxmirrors 配置完成（可能有部分非关键警告）"
    fi

    log_info "安装基础系统包..."
    if command_exists apt-get; then
        sudo_cmd apt-get update -qq
        sudo_cmd apt-get install -y -qq \
            net-tools iputils-ping telnet zip unzip \
            build-essential binutils gcc make cmake \
            git git-core curl openssl libssl-dev wget vim \
            pkg-config autoconf automake g++ ccache \
            tcl-dev libexpat1-dev libpcre3-dev libcap-dev libcap2 \
            bison flex ca-certificates bsdmainutils
    elif command_exists dnf; then
        sudo_cmd dnf install -y \
            net-tools iputils telnet zip unzip \
            gcc gcc-c++ make cmake \
            git curl openssl openssl-devel wget vim \
            pkgconfig autoconf automake ccache \
            expat-devel pcre-devel libcap-devel \
            bison flex ca-certificates
    elif command_exists yum; then
        sudo_cmd yum install -y \
            net-tools iputils telnet zip unzip \
            gcc gcc-c++ make cmake \
            git curl openssl openssl-devel wget vim \
            pkgconfig autoconf automake ccache \
            expat-devel pcre-devel libcap-devel \
            bison flex ca-certificates
    fi

    log_info "基础依赖安装完成"
}

# ============================================================================
# Module: docker
# ============================================================================
install_docker() {
    local use_cn="${1:-false}"

    log_step "安装 Docker CE..."

    local docker_opts=""
    if [ "$use_cn" = "true" ] && [ -n "${MIRROR_DOCKER:-}" ]; then
        log_info "使用 Docker 镜像: ${MIRROR_DOCKER}"
        docker_opts="--mirror ${MIRROR_DOCKER}"
    fi

    curl -fsSL https://get.docker.com -o "${INSTALL_TMPDIR}/install_docker.sh"
    chmod +x "${INSTALL_TMPDIR}/install_docker.sh"
    sudo_cmd sh "${INSTALL_TMPDIR}/install_docker.sh" ${docker_opts}

    if ! is_docker_env; then
        sudo_cmd usermod -aG docker "$(whoami)" 2>/dev/null || true
    fi

    log_info "Docker CE 安装完成"
}

# ============================================================================
# Module: uv (Python)
# ============================================================================
install_uv() {
    local use_cn="${1:-false}"

    log_step "安装 uv (Python 包管理器)..."

    local uv_install_url="https://astral.sh/uv/install.sh"

    if [ "$use_cn" = "true" ]; then
        export UV_DEFAULT_INDEX="${MIRROR_PYPI_INDEX}"
        log_info "UV 使用 PyPI 镜像: ${MIRROR_PYPI_INDEX}"
        if [ -n "${MIRROR_FOR_GITHUB:-}" ]; then
            export UV_INSTALLER_GHE_BASE_URL="${MIRROR_FOR_GITHUB}/https://github.com"
            export UV_PYTHON_INSTALL_MIRROR="${MIRROR_FOR_GITHUB}/https://github.com/indygreg/python-build-standalone/releases/download"
            log_info "UV 使用 GitHub 代理: ${MIRROR_FOR_GITHUB}"
        fi
    fi

    curl -LsSf "$uv_install_url" -o "${INSTALL_TMPDIR}/install_uv.sh"

    if [ "$use_cn" = "true" ]; then
        sed_github_mirror "${INSTALL_TMPDIR}/install_uv.sh"
    fi

    chmod +x "${INSTALL_TMPDIR}/install_uv.sh"
    env \
        UV_INSTALLER_GHE_BASE_URL="${UV_INSTALLER_GHE_BASE_URL:-}" \
        UV_PYTHON_INSTALL_MIRROR="${UV_PYTHON_INSTALL_MIRROR:-}" \
        UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX:-}" \
        bash "${INSTALL_TMPDIR}/install_uv.sh"

    export PATH="$HOME/.local/bin:$PATH"
    log_info "uv 安装完成"

    log_info "安装 Python 3.11..."
    uv python install 3.11 2>/dev/null || log_warn "Python 3.11 安装可能已完成或失败"

    log_info "Python 环境安装完成"
}

# ============================================================================
# Module: nvm (Node.js)
# ============================================================================
install_nvm() {
    local use_cn="${1:-false}"

    log_step "安装 nvm (Node.js 版本管理器)..."

    local nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh"

    if [ "$use_cn" = "true" ]; then
        nvm_url=$(github_mirror_url "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh")
        export NVM_NODEJS_ORG_MIRROR="${MIRROR_NODE}"
        log_info "NVM 使用 Node.js 镜像: ${MIRROR_NODE}"
        if [ -n "${MIRROR_FOR_GITHUB:-}" ]; then
            log_info "NVM 使用 GitHub 代理: ${MIRROR_FOR_GITHUB}"
        fi
    fi

    curl -fsSL "$nvm_url" -o "${INSTALL_TMPDIR}/install_nvm.sh"

    if [ "$use_cn" = "true" ]; then
        sed_github_mirror "${INSTALL_TMPDIR}/install_nvm.sh"
    fi

    chmod +x "${INSTALL_TMPDIR}/install_nvm.sh"

    # Use script method (more reliable in containers with limited git/network access)
    env NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-}" \
        METHOD=script \
        bash "${INSTALL_TMPDIR}/install_nvm.sh"

    setup_nvm_env

    log_info "安装 Node.js LTS..."
    set +u  # nvm uses unbound variables internally
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    set -u

    if [ "$use_cn" = "true" ]; then
        log_info "配置 npm 使用国内镜像: ${MIRROR_NPM_REGISTRY}"
        npm config set registry "${MIRROR_NPM_REGISTRY}"
    fi

    log_info "安装全局 npm 包 (typescript, bun, yarn, pnpm)..."
    npm install -g typescript bun yarn pnpm@latest-11

    log_info "Node.js 环境安装完成"
}

# ============================================================================
# Module: rustup (Rust)
# ============================================================================
install_rustup() {
    local use_cn="${1:-false}"

    log_step "安装 rustup (Rust 工具链管理器)..."

    local rustup_url="https://sh.rustup.rs"

    if [ "$use_cn" = "true" ]; then
        export RUSTUP_DIST_SERVER="${MIRROR_RUSTUP_DIST}"
        export RUSTUP_UPDATE_ROOT="${MIRROR_RUSTUP_UPDATE}"
        log_info "Rustup 使用 Dist 镜像: ${MIRROR_RUSTUP_DIST}"
        log_info "Rustup 使用 Update 镜像: ${MIRROR_RUSTUP_UPDATE}"
        if [ -n "${MIRROR_FOR_GITHUB:-}" ]; then
            log_info "Rustup 使用 GitHub 代理: ${MIRROR_FOR_GITHUB}"
        fi
    fi

    curl --proto '=https' --tlsv1.2 -sSf "$rustup_url" -o "${INSTALL_TMPDIR}/install_rustup.sh"

    if [ "$use_cn" = "true" ]; then
        sed_github_mirror "${INSTALL_TMPDIR}/install_rustup.sh"
    fi

    chmod +x "${INSTALL_TMPDIR}/install_rustup.sh"
    env RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-}" \
        RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-}" \
        bash "${INSTALL_TMPDIR}/install_rustup.sh" -y

    set +u; setup_cargo_env; set -u

    log_info "安装 Rust stable 工具链..."
    rustup toolchain install stable
    rustup default stable

    if [ "$use_cn" = "true" ]; then
        log_info "配置 Cargo 使用国内镜像: ${MIRROR_CARGO_REGISTRY}"
        local cargo_config_dir="$HOME/.cargo"
        mkdir -p "$cargo_config_dir"
        cat > "$cargo_config_dir/config.toml" <<'CARGO_TOML'
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'mirror'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

[source.rustcc]
registry = "git://crates.rustcc.com/crates.io-index"

[source.rustcc2]
registry = "git://crates.rustcc.cn/crates.io-index"

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
CARGO_TOML
        sed -i "s/replace-with = 'mirror'/replace-with = '${MIRROR_CARGO_REGISTRY}'/" "$cargo_config_dir/config.toml"
    fi

    log_info "Rust 环境安装完成"
}

# ============================================================================
# Module: gvm (Go)
# ============================================================================
install_gvm() {
    local use_cn="${1:-false}"

    log_step "安装 gvm (Go 版本管理器)..."

    local gvm_url="https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer"

    if [ "$use_cn" = "true" ]; then
        gvm_url=$(github_mirror_url "https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer")
        log_info "Go 模块代理: ${MIRROR_GO_PROXY}"
        log_info "Go 二进制镜像: ${MIRROR_GO_BINARY}"
        if [ -n "${MIRROR_FOR_GITHUB:-}" ]; then
            log_info "GVM 使用 GitHub 代理: ${MIRROR_FOR_GITHUB}"
        fi
    fi

    curl -s -S -L "$gvm_url" -o "${INSTALL_TMPDIR}/install_gvm.sh"

    if [ "$use_cn" = "true" ]; then
        sed_github_mirror "${INSTALL_TMPDIR}/install_gvm.sh"
    fi

    chmod +x "${INSTALL_TMPDIR}/install_gvm.sh"
    set +u; bash "${INSTALL_TMPDIR}/install_gvm.sh"; set -u

    if [ "$use_cn" = "true" ]; then
        sed_github_mirror "$HOME/.gvm/scripts/install"
    fi

    local profile_scripts=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile")
    for pf in "${profile_scripts[@]}"; do
        if [ -f "$pf" ]; then
            if ! grep -q "GO111MODULE" "$pf" 2>/dev/null; then
                cat >> "$pf" <<GVM_ENV

# Go environment (added by dev-env-setups)
export GO111MODULE=on
export GOPROXY=${MIRROR_GO_PROXY}
export GO_BINARY_BASE_URL=${MIRROR_GO_BINARY}
GVM_ENV
            fi
        fi
    done

    export GO111MODULE=on
    export GOPROXY="${MIRROR_GO_PROXY}"
    export GO_BINARY_BASE_URL="${MIRROR_GO_BINARY}"

    set +u
    [ -s "$HOME/.gvm/scripts/gvm" ] && source "$HOME/.gvm/scripts/gvm"

    log_info "安装 Go 1.24.13（binary模式）..."
    set +u
    gvm install go1.24.13 --binary || log_warn "Go 1.24.13 可能已安装或安装失败，请手动检查"
    gvm use go1.24.13 --default 2>/dev/null || true
    set -u

    log_info "Go 环境安装完成"
}

# ============================================================================
# Module: sdkman (Java)
# ============================================================================
install_sdkman() {
    local use_cn="${1:-false}"

    log_step "安装 sdkman (JDK 版本管理器)..."

    curl -s "https://get.sdkman.io" -o "${INSTALL_TMPDIR}/install_sdkman.sh"
    chmod +x "${INSTALL_TMPDIR}/install_sdkman.sh"
    set +u; bash "${INSTALL_TMPDIR}/install_sdkman.sh"; set -u

    set +u; setup_sdkman_env; set -u

    log_info "安装 Java 25.0.2-ms..."
    set +u
    sdk install java 25.0.2-ms 2>/dev/null || log_warn "Java 25.0.2-ms 可能已安装或安装失败"
    sdk default java 25.0.2-ms 2>/dev/null || true
    set -u

    log_info "Java 环境安装完成"
}

# ============================================================================
# Module: code-server
# ============================================================================
install_code_server() {
    local use_cn="${1:-false}"
    local cs_version="${CODE_SERVER_VERSION:-4.128.0}"
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *)       log_error "不支持的架构: $arch"; return 1 ;;
    esac

    log_step "安装 code-server v${cs_version} (${arch})..."

    local cs_url="https://github.com/coder/code-server/releases/download/v${cs_version}/code-server-${cs_version}-linux-${arch}.tar.gz"

    if [ "$use_cn" = "true" ] && [ -n "${MIRROR_FOR_GITHUB:-}" ]; then
        cs_url=$(github_mirror_url "$cs_url")
        log_info "使用 GitHub 代理下载 code-server"
    fi

    log_info "下载 code-server release (~188MB, 可能需要几分钟)..."
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 \
        -o "${INSTALL_TMPDIR}/code-server.tar.gz" \
        "$cs_url"

    log_info "安装 code-server 到 /usr/local..."
    sudo_cmd mkdir -p /usr/local/lib /usr/local/bin
    sudo_cmd tar -C /usr/local/lib -xzf "${INSTALL_TMPDIR}/code-server.tar.gz"
    sudo_cmd mv "/usr/local/lib/code-server-${cs_version}-linux-${arch}" \
                "/usr/local/lib/code-server-${cs_version}"
    sudo_cmd ln -fs "/usr/local/lib/code-server-${cs_version}/bin/code-server" \
                     /usr/local/bin/code-server

    # GitHub Copilot 扩展安装（仅在非 Docker 环境尝试，需要访问 VS Code marketplace）
    if ! is_docker_env && command_exists code-server; then
        log_info "安装 GitHub Copilot 扩展..."
        export EXTENSIONS_GALLERY='{"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery", "itemUrl": "https://marketplace.visualstudio.com/items"}'
        code-server --install-extension github.copilot --force 2>/dev/null || \
            log_warn "GitHub Copilot 扩展安装失败（可能需要 code-server 重启后手动安装）"
    fi

    log_info "code-server v${cs_version} 安装完成"
}

# ============================================================================
# Module: chsrc (换源工具)
# ============================================================================
install_chsrc() {
    log_step "安装 chsrc (全平台换源工具)..."

    # chsrc downloads from gitee.com, already China-friendly
    curl https://chsrc.run/posix -o "${INSTALL_TMPDIR}/install_chsrc.sh"
    chmod +x "${INSTALL_TMPDIR}/install_chsrc.sh"
    bash "${INSTALL_TMPDIR}/install_chsrc.sh"

    log_info "chsrc 安装完成"
}

# ============================================================================
# Module: xcmd (x-cmd Shell 工具集合)
# ============================================================================
install_xcmd() {
    log_step "安装 x-cmd (Shell 工具集合)..."

    # x-cmd downloads from aliyun OSS, already China-friendly
    curl https://get.x-cmd.com -o "${INSTALL_TMPDIR}/install_xcmd.sh"
    chmod +x "${INSTALL_TMPDIR}/install_xcmd.sh"
    bash "${INSTALL_TMPDIR}/install_xcmd.sh"

    log_info "x-cmd 安装完成"
}
