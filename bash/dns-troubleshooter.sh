#!/bin/bash

set -euo pipefail

RED_BOLD=$'\033[1;31m'
GREEN_BOLD=$'\033[1;32m'
NC=$'\033[0m'
PASS="${GREEN_BOLD}✓${NC}"
FAIL="${RED_BOLD}✗ FAILED${NC}"

check_dns_resolution () {
    dig +short $1 | head -1
}

check_http_status () {
    curl -s -o /dev/null -w "%{http_code}" "http://$1" # TODO: if it returns 000, make it return nothing
}

check_tls_status () {
    openssl s_client -servername "$1" -connect "${1}:443" 2>/dev/null < /dev/null | openssl x509 -noout -enddate | cut -d= -f2
}

check_tls_issuer () {
    openssl s_client -connect "${1}:443" 2>/dev/null < /dev/null | openssl x509 -noout -issuer | sed -n 's/.*CN=\([^,]*\).*/\1/p'
}

check_dns_lookup_time () {
    dig "$1" | grep time | awk '{print $(NF-1)}'
}

check_http_response_time () {
    curl -o /dev/null -s -w "%{time_total}s\n" "$1"
}

validate_check () {
    if ! result=$("$1" "$2") 2>/dev/null || [[ -z "$result" ]] || [[ "$result" == "000" ]]; then
        echo "$FAIL"
        return 1
    fi

    echo "${PASS} ${result}"
}

generate_report () {
    local failed=0

    dns_resolution_result=$(validate_check "check_dns_resolution" "$1") || ((failed++))
    http_status_code_result=$(validate_check "check_http_status" "$1") || ((failed++))
    tls_expiry_date_result=$(validate_check "check_tls_status" "$1") || ((failed++))
    common_name_result=$(validate_check "check_tls_issuer" "$1") || ((failed++))
    http_response_time_result=$(validate_check "check_http_response_time" "$1") || ((failed++))
    dns_lookup_time_result=$(validate_check "check_dns_lookup_time" "$1") || ((failed++))

    if [[ $failed -eq 0 ]]; then
        status="${GREEN_BOLD}HEALTHY${NC}"
    elif [[ $failed -eq 5 ]]; then
        status="${RED_BOLD}UNHEALTHY${NC}"
    else
        status="DEGRADED"
    fi

    printf "================================================\n"
    echo "DNS/HTTP Health Report — ${1}"
    printf "================================================\n"

    printf "%-22s %s\n" "DNS Resolution:"    "$dns_resolution_result"
    printf "%-22s %s\n" "HTTP Status:"       "$http_status_code_result"
    printf "%-22s %s\n" "HTTPS/TLS:"         "$tls_expiry_date_result"
    printf "%-22s %s\n" "TLS Issuer:"        "$common_name_result"
    printf "%-22s %s\n" "HTTP Response Time:" "$http_response_time_result"
    printf "%-22s %s\n" "DNS Lookup Time (ms):" "$dns_lookup_time_result"

    printf "================================================\n"
    printf "Status: ${RED_BOLD}${status}\n"
    printf "================================================\n\n"
}

DOMAIN=$1

printf "Checking $DOMAIN...\n\n"
generate_report $DOMAIN

