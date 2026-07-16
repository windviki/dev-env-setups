#!/bin/bash
set -eo pipefail

RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'
BOLD='\033[1m'; PLAIN='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${PLAIN}  $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${PLAIN}  $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${PLAIN} $*" >&2; }
log_step()  { echo -e "${BLUE}${BOLD}[STEP]${PLAIN}  $*" >&2; }

is_root() { [ "$(id -u)" -eq 0 ]; }
is_docker_env() { [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; }
need_sudo() { ! is_root && ! is_docker_env; }

sudo_cmd() {
    if is_root || is_docker_env; then
        "$@"
    else
        sudo "$@"
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

detect_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

detect_os_codename() {
    if command -v lsb_release &>/dev/null; then
        lsb_release -cs
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${VERSION_CODENAME:-${VERSION_ID}}"
    else
        echo "unknown"
    fi
}

setup_nvm_env() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

setup_sdkman_env() {
    export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
    [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
}

setup_gvm_env() {
    [ -s "$HOME/.gvm/scripts/gvm" ] && source "$HOME/.gvm/scripts/gvm"
}

setup_cargo_env() {
    [ -s "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
}

command_exists() {
    command -v "$1" &>/dev/null
}
