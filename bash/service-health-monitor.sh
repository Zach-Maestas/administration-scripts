#!/bin/bash

set -euo pipefail

GREEN_BOLD=$'\033[1;32m'
YELLOW_BOLD=$'\033[1;33m'
RED_BOLD=$'\033[1;31m'
NC=$'\033[0m'

ACTIVE="${GREEN_BOLD}✓ ACTIVE${NC}"
INACTIVE="${RED_BOLD}✗ INACTIVE${NC}"
NOT_FOUND="${YELLOW_BOLD}⚠ NOT FOUND${NC}"

OVERALL_STATUS_TEXT="✓ NORMAL"
OVERALL_STATUS_COLOR=$GREEN_BOLD

check_service_status () {

    echo "  Service              Status"
    echo "  ----------------------------------------------"

    local exit_code
    for service in $@; do
        exit_code=0
        systemctl is-active --quiet "$service" || exit_code=$?
        if [ $exit_code -eq 0 ]; then
            printf "  %-20s %s\n" "$service" "$ACTIVE"
        elif [ $exit_code -eq 4 ]; then
            printf "  %-20s %s\n" "$service" "$NOT_FOUND"
            if [ "$OVERALL_STATUS_TEXT" != "✗ CRITICAL" ]; then
                OVERALL_STATUS_TEXT="⚠ WARNING"
                OVERALL_STATUS_COLOR=$YELLOW_BOLD
            fi
        else
            printf "  %-20s %s\n" "$service" "$INACTIVE"
            OVERALL_STATUS_TEXT="✗ CRITICAL"
            OVERALL_STATUS_COLOR=$RED_BOLD
        fi
    done

    echo ""
}

printf "\n================================================\n"
printf "Service Health Report — %s\n" $(hostname)
echo "$(date +"%Y-%m-%d %H:%M:%S")"
printf "================================================\n\n"

check_service_status $@

echo "================================================"
printf "Overall Status: ${OVERALL_STATUS_COLOR}%s${NC}\n" "$OVERALL_STATUS_TEXT"
printf "================================================\n"
