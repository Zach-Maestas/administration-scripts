#!/bin/bash

# system-health-check.sh
# Collects CPU, memory, and disk metrics and prints a color-coded
# health report with NORMAL / WARNING / CRITICAL status thresholds
# Usage: ./system-health-check.sh

set -euo pipefail

GREEN_BOLD=$'\033[1;32m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

NORMAL="${GREEN_BOLD}✓ NORMAL${NC}"
WARNING="${YELLOW_BOLD}⚠ WARNING${NC}"
CRITICAL="${RED_BOLD}✗ CRITICAL${NC}"

MIB_TO_GIB=1024

get_cpu_usage () {
    # -bn1: batch mode, single iteration — avoids interactive output and CPU averaging across samples
    # $8 is the idle% column; subtracting from 100 gives total usage
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - int($8)}'
}

get_memory_usage () {
    local total_mem used_mem free_mem mem_usage total_mem_gib used_mem_gib free_mem_gib

    # --mega reads in MiB (powers of 1024) not SI megabytes, keeping integer division exact for GiB conversion
    read -r total_mem used_mem free_mem <<< "$(free --mega | awk '/Mem:/{print $2, $3, $4}')"
    
    mem_usage=$(( $used_mem * 100 / $total_mem ))
    total_mem_gib=$(( total_mem / $MIB_TO_GIB ))
    used_mem_gib=$(( used_mem / $MIB_TO_GIB ))
    free_mem_gib=$(( $total_mem_gib - $used_mem_gib ))

    echo "$total_mem_gib $used_mem_gib $free_mem_gib $mem_usage"
}

get_disk_usage () {
    printf "  %-14s%-8s%-8s%-8s%-8s%s\n" "Filesystem" "Size" "Used" "Avail" "Use%" "Status"
    printf "  %s\n" "-------------------------------------------------------"
    # index() checks if $1 appears anywhere in the colon-separated exclude string, filtering virtual/overlay filesystems
    df -h | awk -v exclude="tmpfs:devtmpfs:overlay:shm" 'NR >= 2 && !index(exclude, $1) {print}' | while read -r line; do
        local filesystem size used avail usepct capacity status
        read -r filesystem size used avail usepct _ <<< "$line"
        capacity="${usepct//%/}"
        status=$(get_status "$capacity")
        printf "  %-14s%-8s%-8s%-8s%-8s%s\n" "$filesystem" "$size" "$used" "$avail" "$usepct" "$status"
    done
}

get_status () {
    local usage=$1 warn=${2:-80} crit=${3:-90}
    local status=$NORMAL

    if [[ $usage -gt $crit ]]; then
        status=$CRITICAL
    elif [[ $usage -gt $warn ]]; then
        status=$WARNING
    fi

    echo "$status"
}

generate_report () {
    local cpu_usage cpu_status
    cpu_usage=$(get_cpu_usage)
    cpu_status=$(get_status "$cpu_usage")

    local total_mem used_mem free_mem mem_usage mem_status
    read -r total_mem used_mem free_mem mem_usage <<< "$(get_memory_usage)"
    mem_status=$(get_status "$mem_usage")

    local disk_usage_output
    disk_usage_output=$(get_disk_usage)

    local overall_status=$NORMAL
    # Matching against the raw ANSI string, so glob patterns are used instead of exact equality
    if [[ "$cpu_status" == *"CRITICAL"* ]] || [[ "$mem_status" == *"CRITICAL"* ]] || echo "$disk_usage_output" | grep -q "CRITICAL"; then
        overall_status=$CRITICAL
    elif [[ "$cpu_status" == *"WARNING"* ]] || [[ "$mem_status" == *"WARNING"* ]] || echo "$disk_usage_output" | grep -q "WARNING"; then
        overall_status=$WARNING
    fi

    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Running system health check..."
    echo ""
    printf "================================================\n"
    printf "System Health Report — %s\n" "$(hostname)"
    printf "%s\n" "$(date +"%Y-%m-%d %H:%M:%S")"
    printf "================================================\n"
    echo ""

    printf "CPU Usage:\n"
    printf "  %-16s%s\n" "Usage:" "${cpu_usage}%"
    printf "  %-16s%s\n" "Status:" "$cpu_status"
    echo ""

    printf "Memory Usage:\n"
    printf "  %-16s%s\n" "Total:" "${total_mem}GiB"
    printf "  %-16s%s\n" "Used:" "${used_mem}GiB"
    printf "  %-16s%s\n" "Free:" "${free_mem}GiB"
    printf "  %-16s%s\n" "Usage:" "${mem_usage}%"
    printf "  %-16s%s\n" "Status:" "$mem_status"
    echo ""

    printf "Disk Usage:\n"
    echo "$disk_usage_output"
    echo ""

    printf "================================================\n"
    printf "Overall Status:  %s\n" "$overall_status"
    printf "================================================\n"
}

generate_report
