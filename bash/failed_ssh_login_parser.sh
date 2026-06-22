#!/bin/bash

# failed_ssh_login_parser.sh
# Parses auth.log for failed SSH login attempts and generates
# a ranked threat report with risk classification
# Usage: ./failed_ssh_login_parser.sh [log_file_path]

set -euo pipefail

FILE_PATH=${1:-/var/log/auth.log}

parse_log () {
    # NF-3 extracts the IP field from auth.log's "Failed password for user from IP port N ssh2" format
    grep "Failed password" "$FILE_PATH" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
}

generate_report () {
    local RED=$'\033[0;31m'
    local YELLOW=$'\033[0;33m'
    local GREEN=$'\033[0;32m'
    local NC=$'\033[0m'
    local BOLD=$'\033[1m'
    local high_risk_ips=()

    printf "\n======================================\n"
    printf "${BOLD}%-5s %-15s %-10s %s${NC}\n" "RANK" "IP ADDRESS" "ATTEMPTS" "RISK"
    echo "--------------------------------------"

    local rank=1
    while IFS= read -r line; do
        local count ip risk
        count=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')

        risk="${GREEN}LOW"

        if [[ $count -ge 20 ]]; then
            risk="${RED}HIGH"
            high_risk_ips+=("$ip » $count attempts")
        elif [[ $count -ge 10 ]]; then
            risk="${YELLOW}MEDIUM"
        fi

        printf "%-5s %-15s %-10s %s${NC}\n" "$rank" "$ip" "$count" "$risk"
        ((rank++))
    done
    echo "======================================"
    printf "Total unique IPs: $((rank - 1))\n\n"

    if [[ ${#high_risk_ips[@]} -eq 0 ]]; then
        printf "No high risk IPs detected\n\n"
    else
        printf "⚠️  HIGH RISK ALERT — Immediate attention required:\n"
        echo "   -----------------------------------------------"
        for entry in "${high_risk_ips[@]}"; do
            echo "     $entry"
        done
        printf "\n"
    fi
}

log_message () {
    local timestamp=$(date "+%Y-%m-%d %T")
    printf "[$timestamp] $1"
}

if [[ ! -f $FILE_PATH ]]; then
    log_message "File not found\n"
    exit 2
fi

LOG_FILE="ssh_parser_$(date '+%Y-%m-%d_%H%M%S').log"

# Strip ANSI color codes before writing to log file
exec > >(tee >(sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE")) 2>&1

log_message "Processing log file...\n"
parse_log | generate_report
log_message "Report saved to $LOG_FILE\n"
