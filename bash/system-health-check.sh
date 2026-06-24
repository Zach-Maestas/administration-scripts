#!/bin/bash

set -euo pipefail

GREEN_BOLD=$'\033[1;32m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

NORMAL_STATUS="${GREEN_BOLD}✓ NORMAL${NC}"
WARNING_STATUS="${YELLOW_BOLD}⚠ WARNING${NC}"
CRITICAL_STATUS="${RED_BOLD}✗ CRITICAL${NC}"


get_cpu_usage () {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - int($8)}'
}

get_memory_usage () {
    local total_mem used_mem free_mem mem_usage

    read -r total_mem used_mem free_mem <<< "$(free --mega | awk '/Mem:/{print $2, $3, $4}')"
    mem_usage=$(( $used_mem * 100 / $total_mem ))

    echo "$total_mem $used_mem $free_mem $mem_usage"
}

get_disk_usage () {
    echo ""
}

get_cpu_status () {
    local cpu_usage=$1
    local cpu_status="NORMAL"

    if [[ $cpu_usage -gt 90 ]]; then
        cpu_status="CRITICAL"
    elif [[ $cpu_usage -gt 80 ]]; then
        cpu_status="WARNING"
    fi

    echo "$cpu_status"
}

get_memory_status () {
    local mem_usage=$1
    local mem_status="NORMAL"

    if [[ $mem_usage -gt 90 ]]; then
        mem_status="CRITICAL"
    elif [[ $mem_usage -gt 80 ]]; then
        mem_status="WARNING"
    fi

    echo "$mem_status"
}

get_disk_status () {
    echo ""
}

generate_report () {
    local cpu_usage=$(get_cpu_usage)
    local cpu_status=$(get_cpu_status "$cpu_usage")

    local total_mem used_mem free_mem mem_usage
    read -r total_mem used_mem free_mem mem_usage <<< "$(get_memory_usage)"

    printf "CPU Usage:\n"
    printf "Usage: $cpu_usage\n"
    printf "Status: $cpu_status\n"
}

generate_report