#!/bin/bash

set -euo pipefail

get_cpu_usage () {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}'
}

get_memory_usage () {

}

get_disk_usage () {

}

perform_checks () {
    local CPU_USAGE=$1
    local CPU_STATUS="NORMAL"

    if [[ $CPU_USAGE -gt 90 ]]; then
        CPU_STATUS="CRITICAL"
    elif [[ $CPU_USAGE -gt 80 ]]; then
        CPU_STATUS="WARNING"
    fi

    echo "$CPU_STATUS"
}