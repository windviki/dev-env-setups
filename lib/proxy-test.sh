#!/bin/bash
# Auto-detect the fastest available GitHub proxy for China mainland.
#
# Usage:
#   source lib/proxy-test.sh        # set MIRROR_FOR_GITHUB env var
#   bash lib/proxy-test.sh --print  # print the fastest proxy URL
#   bash lib/proxy-test.sh --set    # set and export MIRROR_FOR_GITHUB
#
# Sources: https://github.akams.cn/ (node speed test page)
# If detection fails, falls back to default: https://ghfast.top

set -euo pipefail

DEFAULT_GITHUB_PROXY="https://ghfast.top"

# Well-known GitHub proxy services for China mainland
KNOWN_PROXIES=(
    "https://ghfast.top"
    "https://gh-proxy.com"
    "https://gh.llkk.cc"
    "https://gh.ddlc.top"
)

test_proxy_speed() {
    local proxy="$1"
    local test_url="${proxy}/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh"
    local start_time end_time elapsed

    start_time=$(date +%s%N)
    if curl -fsSL --connect-timeout 5 --max-time 10 -o /dev/null "$test_url" 2>/dev/null; then
        end_time=$(date +%s%N)
        elapsed=$(( (end_time - start_time) / 1000000 ))
        echo "$elapsed"
        return 0
    else
        return 1
    fi
}

find_fastest_proxy() {
    local best_proxy="$DEFAULT_GITHUB_PROXY"
    local best_time=999999
    local found_working=false

    echo "正在测速 GitHub 代理节点..." >&2

    for proxy in "${KNOWN_PROXIES[@]}"; do
        local elapsed
        if elapsed=$(test_proxy_speed "$proxy"); then
            found_working=true
            echo "  ${proxy} ... ${elapsed}ms" >&2
            if [ "$elapsed" -lt "$best_time" ]; then
                best_time="$elapsed"
                best_proxy="$proxy"
            fi
        else
            echo "  ${proxy} ... 超时" >&2
        fi
    done

    if [ "$found_working" = "true" ]; then
        echo "最快节点: ${best_proxy} (${best_time}ms)" >&2
        echo "$best_proxy"
    else
        echo "所有节点均超时，使用默认: ${DEFAULT_GITHUB_PROXY}" >&2
        echo "$DEFAULT_GITHUB_PROXY"
    fi
}

# Main
case "${1:-}" in
    --print)
        find_fastest_proxy
        ;;
    --set)
        MIRROR_FOR_GITHUB=$(find_fastest_proxy)
        export MIRROR_FOR_GITHUB
        echo "export MIRROR_FOR_GITHUB=${MIRROR_FOR_GITHUB}"
        ;;
    *)
        # When sourced, set the variable silently (only log to stderr)
        if (return 0 2>/dev/null); then
            MIRROR_FOR_GITHUB=$(find_fastest_proxy)
            export MIRROR_FOR_GITHUB
        else
            echo "Usage: $0 [--print|--set]"
            echo "  --print   Print fastest proxy URL"
            echo "  --set     Export MIRROR_FOR_GITHUB"
            echo ""
            echo "Or source this script: source $0"
            exit 1
        fi
        ;;
esac
