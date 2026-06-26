#!/bin/bash

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
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - int($8)}'
}

get_memory_usage () {
    local total_mem used_mem free_mem mem_usage total_mem_gb used_mem_gb free_mem_gb

    read -r total_mem used_mem free_mem <<< "$(free --mega | awk '/Mem:/{print $2, $3, $4}')"
    
    mem_usage=$(( $used_mem * 100 / $total_mem ))
    total_mem_gb=$(( total_mem / $MIB_TO_GIB ))
    used_mem_gb=$(( used_mem / $MIB_TO_GIB ))
    free_mem_gb=$(( free_mem / $MIB_TO_GIB ))

    echo "$total_mem_gb $used_mem_gb $free_mem_gb $mem_usage"
}

get_disk_usage () {
    printf "  %-14s%-8s%-8s%-8s%-8s%s\n" "Filesystem" "Size" "Used" "Avail" "Use%" "Status"
    printf "  %s\n" "-------------------------------------------------------"
    df -h | awk 'NR >= 2 {print}' | while read -r line; do
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
    printf "  %-16s%s\n" "Total:" "${total_mem}GB"
    printf "  %-16s%s\n" "Used:" "${used_mem}GB"
    printf "  %-16s%s\n" "Free:" "${free_mem}GB"
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
