#!/usr/bin/env python3
"""Parse Docker build log to extract per-module timing."""
import re
import sys

logfile = sys.argv[1] if len(sys.argv) > 1 else "logs/docker-build-timed-20260716_103241.log"

with open(logfile, "r") as f:
    lines = f.readlines()

# Extract module boundaries from step #6 internal timestamps
print("=== 模块耗时分析 ===")
print()

prev_name = None
prev_ts = None
total_module_time = 0

for line in lines:
    # Match module start lines in step #6
    m = re.search(r'#6\s+(\d+\.\d+).*?开始安装模块:.*?\[1m(\S+)\[0m', line)
    if m:
        ts = float(m.group(1))
        name = m.group(2)
        if prev_name is not None:
            elapsed = ts - prev_ts
            print(f"  {prev_name:15s}: {elapsed:6.1f}s ({elapsed/60:.1f}分)")
            total_module_time += elapsed
        prev_name = name
        prev_ts = ts

# Last module to step end
m = re.search(r'#6\s+(\d+\.\d+)s', ''.join(lines[-50:]))
if m and prev_name is not None:
    elapsed = float(m.group(1)) - prev_ts
    print(f"  {prev_name:15s}: {elapsed:6.1f}s ({elapsed/60:.1f}分)")
    total_module_time += elapsed

# Step 6 total
for line in lines:
    m = re.search(r'#6 DONE (\d+\.\d+)s', line)
    if m:
        step6_total = float(m.group(1))
        apt_overhead = step6_total - total_module_time
        print()
        print(f"  {'模块安装合计':15s}: {total_module_time:6.1f}s ({total_module_time/60:.1f}分)")
        print(f"  {'Step 6 总计(RUN)':15s}: {step6_total:6.1f}s ({step6_total/60:.1f}分)")
        print(f"  {'apt-get/system':15s}: {apt_overhead:6.1f}s ({apt_overhead/60:.1f}分)")
        print(f"  {'其他 步骤':15s}: ...")
        break

# Extract all step timings
print()
print("=== Docker 各步骤耗时 ===")
for line in lines:
    m = re.search(r'#(\d+) DONE (\d+\.\d+)s', line)
    if m:
        step = m.group(1)
        t = float(m.group(2))
        print(f"  Step {step}: {t:.0f}s ({t/60:.1f}分)")

# Total build time
print()
for line in lines:
    m = re.search(r'\[(\d{2}):(\d{2}):(\d{2})\].*building with', line)
    if m:
        h, mi, s = map(int, m.groups())
        t0 = h * 3600 + mi * 60 + s
    m = re.search(r'\[(\d{2}):(\d{2}):(\d{2})\].*BUILD COMPLETE', line)
    if m:
        h, mi, s = map(int, m.groups())
        t1 = h * 3600 + mi * 60 + s
        total = t1 - t0
        print(f"  总构建时间: {total}s ({total//60}分{total%60}秒)")

# Verification results
print()
print("=== 构建验证结果 ===")
for line in lines:
    if line.startswith("=== 验证 ===") or any(t in line for t in ["uv:", "node:", "rustc:", "go:", "java:", "code-server:"]):
        print(f"  {line.rstrip()}")
