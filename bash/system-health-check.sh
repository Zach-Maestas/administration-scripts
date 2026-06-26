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
    echo "Filesystem    Size    Used    Avail   Use%    Status"
    df -h | awk 'NR >= 2 {print}' | while read line; do
        local capacity
        capacity=$(echo "$line" | awk '{gsub(/%/, "", $5); print $5}')
        printf "%s %s\n" "$(echo "$line" | awk '{print $1, $2, $3, $4, $5}')" "$(get_status "$capacity")"
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
    local cpu_usage=$(get_cpu_usage)
    local cpu_status=$(get_status "$cpu_usage")

    local total_mem used_mem free_mem mem_usage mem_status
    read -r total_mem used_mem free_mem mem_usage <<< "$(get_memory_usage)"
    mem_status=$(get_status $mem_usage)

    printf "CPU Usage:\n"
    printf "Usage: $cpu_usage\n"
    printf "Status: $cpu_status\n"

    printf "Memory Usage:\n"
    printf "Total: $total_mem\n"
    printf "Used: $used_mem\n"
    printf "Free: $free_mem\n"
    printf "Usage: $mem_usage\n"
    printf "Status: $mem_status\n"

    get_disk_usage
}

generate_report
