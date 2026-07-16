#!/bin/bash
# Mirror configuration for China mainland network environment
# Each mirror type can be overridden via environment variable or command-line argument.
#
# Mirror Types:
#   1. GITHUB_PROXY    - Prepend proxy prefix to github.com URLs in install scripts
#                        Env: MIRROR_FOR_GITHUB
#                        Default: https://gh.llkk.cc
#   2. APT_SOURCE      - System APT source mirror (used by linuxmirrors)
#                        Env: MIRROR_APT_SOURCE
#                        Default: mirrors.ustc.edu.cn
#   3. DOCKER_MIRROR   - Docker CE package mirror
#                        Env: MIRROR_DOCKER
#                        Default: Aliyun
#   4. PYPI_INDEX      - PyPI mirror for Python packages
#                        Env: MIRROR_PYPI_INDEX
#                        Default: https://pypi.tuna.tsinghua.edu.cn/simple
#   5. NPM_REGISTRY    - npm registry mirror
#                        Env: MIRROR_NPM_REGISTRY
#                        Default: https://registry.npmmirror.com
#   6. NODE_MIRROR     - Node.js binary download mirror
#                        Env: MIRROR_NODE
#                        Default: https://npmmirror.com/mirrors/node
#   7. RUSTUP_DIST     - Rustup distribution server
#                        Env: MIRROR_RUSTUP_DIST
#                        Default: https://mirrors.tuna.tsinghua.edu.cn/rustup
#   8. RUSTUP_UPDATE   - Rustup update root
#                        Env: MIRROR_RUSTUP_UPDATE
#                        Default: https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
#   9. CARGO_REGISTRY  - Cargo crates.io registry mirror name (rsproxy/tuna/ustc/sjtu/rustcc)
#                        Env: MIRROR_CARGO_REGISTRY
#                        Default: rsproxy
#   10. GO_PROXY       - Go module proxy
#                        Env: MIRROR_GO_PROXY
#                        Default: https://goproxy.cn,direct
#   11. GO_BINARY      - Go binary download URL
#                        Env: MIRROR_GO_BINARY
#                        Default: https://mirrors.aliyun.com/golang/

MIRROR_FOR_GITHUB="${MIRROR_FOR_GITHUB:-https://gh.llkk.cc}"
MIRROR_APT_SOURCE="${MIRROR_APT_SOURCE:-mirrors.ustc.edu.cn}"
MIRROR_DOCKER="${MIRROR_DOCKER:-Aliyun}"
MIRROR_PYPI_INDEX="${MIRROR_PYPI_INDEX:-https://pypi.tuna.tsinghua.edu.cn/simple}"
MIRROR_NPM_REGISTRY="${MIRROR_NPM_REGISTRY:-https://registry.npmmirror.com}"
MIRROR_NODE="${MIRROR_NODE:-https://npmmirror.com/mirrors/node}"
MIRROR_RUSTUP_DIST="${MIRROR_RUSTUP_DIST:-https://mirrors.tuna.tsinghua.edu.cn/rustup}"
MIRROR_RUSTUP_UPDATE="${MIRROR_RUSTUP_UPDATE:-https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup}"
MIRROR_CARGO_REGISTRY="${MIRROR_CARGO_REGISTRY:-rsproxy}"
MIRROR_GO_PROXY="${MIRROR_GO_PROXY:-https://goproxy.cn,direct}"
MIRROR_GO_BINARY="${MIRROR_GO_BINARY:-https://mirrors.aliyun.com/golang/}"

export_mirror_env() {
    local profile_file="$1"
    cat >> "$profile_file" <<'SHELL_ENV'

# === China Mirror Configuration (added by dev-env-setups) ===
SHELL_ENV
    cat >> "$profile_file" <<SHELL_ENV
export MIRROR_FOR_GITHUB="${MIRROR_FOR_GITHUB}"
export NVM_NODEJS_ORG_MIRROR="${MIRROR_NODE}"
export RUSTUP_DIST_SERVER="${MIRROR_RUSTUP_DIST}"
export RUSTUP_UPDATE_ROOT="${MIRROR_RUSTUP_UPDATE}"
export GO111MODULE=on
export GOPROXY="${MIRROR_GO_PROXY}"
export GO_BINARY_BASE_URL="${MIRROR_GO_BINARY}"
SHELL_ENV
}

# Github URL rewriting: prefix the github proxy to github.com URLs
github_mirror_url() {
    local url="$1"
    echo "${url//https:\/\/github.com/${MIRROR_FOR_GITHUB}/https://github.com}"
}

# Replace github.com in a file with the mirror proxy URL
sed_github_mirror() {
    local file="$1"
    sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" "$file"
    sed -i "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g" "$file"
}
