#!/bin/bash
# Mirror configuration for China mainland network environment
# Each mirror type can be overridden via environment variable or command-line argument.
#
# Mirror Types (14 kinds, 4 categories):
#
#   1. GITHUB_PROXY    - Prepend proxy prefix to github.com URLs in install scripts
#                        Env: MIRROR_FOR_GITHUB
#                        Default: https://ghfast.top
#       Mechanism: URL字符串前缀改写
#       Affect: nvm, rustup, gvm, code-server, uv

#   2. APT_SOURCE      - System APT source mirror (used by linuxmirrors)
#                        Env: MIRROR_APT_SOURCE
#                        Default: mirrors.ustc.edu.cn
#       Mechanism: linuxmirrors 脚本替换 /etc/apt/sources.list

#   3. DOCKER_MIRROR   - Docker CE package mirror (Aliyun/AzureChinaCloud)
#                        Env: MIRROR_DOCKER
#                        Default: Aliyun
#       Mechanism: --mirror 命令行参数

#   4. PYPI_INDEX      - PyPI mirror for Python packages
#                        Env: MIRROR_PYPI_INDEX
#                        Default: https://pypi.tuna.tsinghua.edu.cn/simple
#       Mechanism: UV_DEFAULT_INDEX 环境变量

#   5. NPM_REGISTRY    - npm registry mirror
#                        Env: MIRROR_NPM_REGISTRY
#                        Default: https://registry.npmmirror.com
#       Mechanism: npm config set registry 命令

#   6. NODE_MIRROR     - Node.js binary download mirror
#                        Env: MIRROR_NODE
#                        Default: https://npmmirror.com/mirrors/node
#       Mechanism: NVM_NODEJS_ORG_MIRROR 环境变量

#   7. RUSTUP_DIST     - Rustup distribution server
#                        Env: MIRROR_RUSTUP_DIST
#                        Default: https://mirrors.tuna.tsinghua.edu.cn/rustup
#       Mechanism: RUSTUP_DIST_SERVER 环境变量

#   8. RUSTUP_UPDATE   - Rustup update root
#                        Env: MIRROR_RUSTUP_UPDATE
#                        Default: https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
#       Mechanism: RUSTUP_UPDATE_ROOT 环境变量

#   9. CARGO_REGISTRY  - Cargo crates.io registry mirror name
#                        Valid: rsproxy / tuna / ustc / sjtu / rustcc / rustcc2
#                        Env: MIRROR_CARGO_REGISTRY
#                        Default: rsproxy
#       Mechanism: ~/.cargo/config.toml 中 replace-with 配置

#   10. GO_PROXY       - Go module proxy
#                        Env: MIRROR_GO_PROXY
#                        Default: https://goproxy.cn,direct
#       Mechanism: GOPROXY 环境变量

#   11. GO_BINARY      - Go binary download URL
#                        Env: MIRROR_GO_BINARY
#                        Default: https://mirrors.aliyun.com/golang/
#       Mechanism: GO_BINARY_BASE_URL 环境变量

#   12. RUBY_BUILD     - Ruby source tarball download mirror
#                        Env: MIRROR_RUBY_BUILD
#                        Default: https://mirrors.aliyun.com/ruby
#       Mechanism: RUBY_BUILD_MIRROR_URL 环境变量

#   13. RUBYGEMS       - RubyGems mirror for gem/bundle install
#                        Env: MIRROR_RUBYGEMS_SOURCE
#                        Default: https://gems.ruby-china.com
#       Mechanism: gem sources + bundle config 命令

#   14. PHP_SOURCE     - PHP source tarball download mirror for phpbrew
#                        Env: MIRROR_PHP_SOURCE
#                        Default: https://mirrors.aliyun.com/php-src
#       Mechanism: phpbrew 编译参数 --old-src-url

MIRROR_FOR_GITHUB="${MIRROR_FOR_GITHUB:-https://ghfast.top}"
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

# 12. RUBY_BUILD_MIRROR - Ruby source tarball download mirror
#                        Env: MIRROR_RUBY_BUILD
#                        Default: https://mirrors.aliyun.com/ruby
#       Mechanism: RUBY_BUILD_MIRROR_URL 环境变量

# 13. RUBYGEMS_SOURCE   - RubyGems mirror for gem/bundle install
#                        Env: MIRROR_RUBYGEMS_SOURCE
#                        Default: https://gems.ruby-china.com
#       Mechanism: gem sources + bundle config 命令

# 14. PHP_SOURCE_MIRROR - PHP source tarball download mirror for phpbrew
#                        Env: MIRROR_PHP_SOURCE
#                        Default: https://mirrors.aliyun.com/php-src
#       Mechanism: phpbrew 编译参数 --old-src-url

MIRROR_RUBY_BUILD="${MIRROR_RUBY_BUILD:-https://mirrors.aliyun.com/ruby}"
MIRROR_RUBYGEMS_SOURCE="${MIRROR_RUBYGEMS_SOURCE:-https://gems.ruby-china.com}"
MIRROR_PHP_SOURCE="${MIRROR_PHP_SOURCE:-https://mirrors.aliyun.com/php-src}"

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
export RUBY_BUILD_MIRROR_URL="${MIRROR_RUBY_BUILD}"
SHELL_ENV
}

# Apply github mirror to a URL (prepend proxy prefix).
# When MIRROR_FOR_GITHUB is empty, return the original URL unchanged.
github_mirror_url() {
    local url="$1"
    if [ -z "${MIRROR_FOR_GITHUB:-}" ]; then
        echo "$url"
    else
        local result="$url"
        result="${result//https:\/\/github.com/${MIRROR_FOR_GITHUB}/https://github.com}"
        result="${result//https:\/\/raw.githubusercontent.com/${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com}"
        echo "$result"
    fi
}

# Replace github.com URLs in a file with mirror proxy URLs.
# When MIRROR_FOR_GITHUB is empty, skip (direct access).
sed_github_mirror() {
    local file="$1"
    if [ -z "${MIRROR_FOR_GITHUB:-}" ]; then
        return 0
    fi
    sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" "$file"
    sed -i "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g" "$file"
}
