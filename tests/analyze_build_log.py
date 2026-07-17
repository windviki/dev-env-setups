#!/usr/bin/env python3
"""Parse Docker build log to extract per-module timing.

Usage:
    uv run python tests/analyze_build_log.py logs/docker-build-timed-YYYYMMDD_HHMMSS.log
    uv run python tests/analyze_build_log.py                    # uses latest log
"""
import re
import sys
import os
from pathlib import Path


def find_latest_log(log_dir="logs"):
    """Find the most recent non-empty build log."""
    logs = sorted(Path(log_dir).glob("docker-build-timed-*.log"))
    # Filter out empty files
    logs = [l for l in logs if l.stat().st_size > 100]
    return str(logs[-1]) if logs else None


logfile = sys.argv[1] if len(sys.argv) > 1 else find_latest_log()
if not logfile:
    print("ERROR: No log file found")
    sys.exit(1)

print(f"分析日志: {logfile}")
print()

with open(logfile, "r") as f:
    lines = f.readlines()

# ── Module timing (from step #6 internal docker timestamps) ──
print("=== 模块耗时分析 (Step 6 RUN 层内) ===")
print(f"{'模块':<14s} {'耗时':>8s} {'占比':>7s}  {'说明'}")
print("-" * 65)

prev_name = None
prev_ts = None
module_times = {}
module_order = []

for line in lines:
    # Match: #6 123.4 [INFO]  开始安装模块: name
    m = re.search(r'#6\s+([\d.]+).*?开始安装模块:.*?\033\[1m(\S+)\033\[0m', line)
    if m:
        ts = float(m.group(1))
        name = m.group(2)
        if prev_name is not None:
            elapsed = ts - prev_ts
            module_times[prev_name] = elapsed
            module_order.append(prev_name)
        prev_name = name
        prev_ts = ts

# Last module
if prev_name is not None and prev_ts is not None:
    # Find the "所有模块安装完成" or "DONE" marker
    for line in lines:
        m = re.search(r'#6\s+([\d.]+).*?(?:所有模块安装完成|DONE)', line)
        if m:
            end_ts = float(m.group(1))
            if end_ts > prev_ts:
                elapsed = end_ts - prev_ts
                module_times[prev_name] = elapsed
                module_order.append(prev_name)
            break

total_module_time = sum(module_times.values())

# Module descriptions
MODULE_INFO = {
    "base":        "系统基础依赖+apt源替换",
    "docker":      "Docker CE 容器引擎",
    "uv":          "Python包管理器+Python 3.11",
    "nvm":         "Node.js版本管理器+Node LTS",
    "rustup":      "Rust工具链+stable",
    "gvm":         "Go版本管理器+Go 1.24",
    "sdkman":      "JDK版本管理器+Java 25",
    "rbenv":       "Ruby版本管理器+Ruby 3.x",
    "phpbrew":     "PHP运行时(ondrej PPA)+Composer",
    "luaenv":      "Lua版本管理器+Lua 5.4+LuaRocks",
    "rig":         "R版本管理器+R release",
    "sqlite3":     "SQLite3 系统安装",
    "perl":        "Perl 系统安装",
    "code-server": "VS Code Web服务端",
    "chsrc":       "全平台换源工具",
    "xcmd":        "x-cmd Shell工具集合",
}

# Sort by time descending for display
sorted_modules = sorted(module_times.items(), key=lambda x: x[1], reverse=True)

for name, elapsed in sorted_modules:
    pct = elapsed / total_module_time * 100 if total_module_time > 0 else 0
    desc = MODULE_INFO.get(name, "")
    bar = "█" * int(pct / 3) if pct > 0 else ""
    print(f"  {name:<12s} {elapsed:6.0f}s ({elapsed/60:4.1f}分) {pct:5.1f}% {bar}")

print("-" * 65)
print(f"  {'模块安装合计':<12s} {total_module_time:6.0f}s ({total_module_time/60:.1f}分)")

# ── Step 6 total ──
for line in lines:
    m = re.search(r'#6 DONE ([\d.]+)s', line)
    if m:
        step6_total = float(m.group(1))
        overhead = step6_total - total_module_time
        print(f"  {'Step 6 总计':<12s} {step6_total:6.0f}s ({step6_total/60:.1f}分)")
        print(f"  {'系统开销':<12s} {overhead:6.0f}s ({overhead/60:.1f}分)")
        break

# ── Docker build steps summary ──
print()
print("=== Docker 各步骤耗时 ===")
step_times = {}
for line in lines:
    m = re.search(r'#(\d+) DONE ([\d.]+)s', line)
    if m:
        step = int(m.group(1))
        t = float(m.group(2))
        step_times[step] = t

STEP_LABELS = {
    1: "FROM ubuntu:22.04",
    2: "ENV 设置",
    3: "RUN apt-get 基础包",
    4: "COPY . /opt/dev-env-setups",
    5: "ENV 镜像变量",
    6: "RUN setup.sh 全部模块",
    7: "ENV PATH",
    8: "RUN 用户创建+权限",
    9: "RUN 清理",
    10: "USER devuser",
    11: "WORKDIR",
    12: "CMD",
}

total_build = sum(step_times.values())
for step in sorted(step_times.keys()):
    t = step_times[step]
    label = STEP_LABELS.get(step, f"Step {step}")
    pct = t / total_build * 100 if total_build > 0 else 0
    bar = "█" * int(pct / 3) if pct > 0 else ""
    print(f"  Step {step:>2d}: {t:6.0f}s ({t/60:5.1f}分) {pct:5.1f}% {bar}  {label}")

print(f"  {'总计':>6s}  {total_build:6.0f}s ({total_build/60:.1f}分)")

# ── Top 3 bottlenecks ──
print()
print("=== 瓶颈分析 ===")
if sorted_modules:
    print(f"  🔴 最慢模块: {sorted_modules[0][0]} ({sorted_modules[0][1]:.0f}s / {sorted_modules[0][1]/60:.1f}分)")
    if len(sorted_modules) > 1:
        print(f"  🟡 第二慢:   {sorted_modules[1][0]} ({sorted_modules[1][1]:.0f}s / {sorted_modules[1][1]/60:.1f}分)")
    if len(sorted_modules) > 2:
        print(f"  🟢 第三慢:   {sorted_modules[2][0]} ({sorted_modules[2][1]:.0f}s / {sorted_modules[2][1]/60:.1f}分)")

# ── Language runtime verification results ──
print()
print("=== 构建验证结果 ===")
for line in lines:
    # Only print lines after "构建验证" marker, capturing tool version lines
    if any(t in line for t in ["uv:", "node:", "rustc:", "go:", "java:",
                                 "ruby:", "php:", "lua:", "R:", "perl:",
                                 "sqlite3:", "composer:", "code-server:",
                                 "nvm ", "rbenv ", "phpbrew ", "luaenv ", "rig ",
                                 "x-cmd:"]):
        # Strip ANSI and timestamps
        clean = re.sub(r'\033\[[0-9;]*m', '', line)
        clean = re.sub(r'^\[\d{2}:\d{2}:\d{2}\]\s*', '', clean)
        print(f"  {clean.rstrip()}")
