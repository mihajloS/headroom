#!/usr/bin/env bash
# Prints the recommended headroom level for this machine and the reason.
# Output: "headroom: <low|medium|high> (<reason>)"
set -u

if [ -n "${HEADROOM_LEVEL:-}" ]; then
  echo "headroom: ${HEADROOM_LEVEL} (set by HEADROOM_LEVEL)"
  exit 0
fi

case "$(uname -s)" in
  Linux)
    cpus=$(nproc)
    mem_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    load=$(cut -d' ' -f1 /proc/loadavg)
    ;;
  Darwin)
    cpus=$(sysctl -n hw.ncpu)
    mem_kb=$(( $(sysctl -n hw.memsize) / 1024 ))
    page=$(sysctl -n hw.pagesize)
    avail_pages=$(vm_stat | awk '/Pages (free|inactive|speculative)/ {gsub(/\./,"",$NF); s+=$NF} END {print s}')
    avail_kb=$(( avail_pages * page / 1024 ))
    load=$(sysctl -n vm.loadavg | awk '{print $2}')
    ;;
  *)
    echo "headroom: low (unknown OS, assuming a small host)"
    exit 0
    ;;
esac

mem_gb=$(awk -v k="$mem_kb" 'BEGIN {printf "%.1f", k/1048576}')
avail_gb=$(awk -v k="$avail_kb" 'BEGIN {printf "%.1f", k/1048576}')

# Base level from capacity.
if [ "$cpus" -le 2 ] || [ "$mem_kb" -le $((4 * 1048576)) ]; then
  level=2
elif [ "$cpus" -le 8 ] || [ "$mem_kb" -le $((16 * 1048576)) ]; then
  level=1
else
  level=0
fi

# Step down one level when the machine is already busy.
busy=""
if awk -v l="$load" -v c="$cpus" 'BEGIN {exit !(l >= c)}'; then
  busy="; busy: load >= CPU count"
elif [ $(( avail_kb * 100 / mem_kb )) -lt 15 ]; then
  busy="; busy: under 15% RAM available"
fi
if [ -n "$busy" ] && [ "$level" -lt 2 ]; then
  level=$(( level + 1 ))
fi

names=(high medium low)
echo "headroom: ${names[$level]} (${cpus} CPU, ${mem_gb} GB RAM, ${avail_gb} GB available, load ${load}${busy})"
