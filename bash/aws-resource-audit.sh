#!/bin/bash

check_aws_account_connection_status () {
    local exit_code=0

    aws sts get-caller-identity > /dev/null || exit_code=$?
    if [ $exit_code -ne 0 ]; then
        printf "[$(date +"%Y-%m-%d %H:%M:%S")] Error! AWS authentication failed\n"
        printf "[$(date +"%Y-%m-%d %H:%M:%S")] Error code: %s\n" $exit_code
        exit 1
    else
        printf "[$(date +"%Y-%m-%d %H:%M:%S")] AWS authentication success!\n"
    fi
}

get_ec2_instances () {
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId[]' --output text
}

get_s3_buckets () {
    :
}

get_rds_instances () {
    :
}

get_ecs_clusters_and_tasks () {
    :
}

get_vpcs_and_nat_gateways () {
    :
}

get_iam_users_and_roles () {
    :
}

get_lambda_functions () {
    :
}

SEPARATOR="$(printf '=%.0s' {1..55})"

print_section () {
    local label="$1"
    local items="$2"
    local count=0
    [ -n "$items" ] && count=$(printf '%s\n' "$items" | wc -l | tr -d ' ')

    printf "\n%s (%s):\n" "$label" "$count"
    [ -n "$items" ] && printf '%s\n' "$items" | sed 's/^/  /'
}

generate_report () {
    local account_id timestamp
    account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local ec2 s3 rds ecs vpcs iam lambda
    ec2=$(get_ec2_instances)
    s3=$(get_s3_buckets)
    rds=$(get_rds_instances)
    ecs=$(get_ecs_clusters_and_tasks)
    vpcs=$(get_vpcs_and_nat_gateways)
    iam=$(get_iam_users_and_roles)
    lambda=$(get_lambda_functions)

    printf "\n%s\n" "$SEPARATOR"
    printf " AWS Resource Audit - %s [%s]\n" "$account_id" "$timestamp"
    printf "%s\n" "$SEPARATOR"

    print_section "EC2 instances"         "$ec2"
    print_section "S3 buckets"            "$s3"
    print_section "RDS instances"         "$rds"
    print_section "ECS clusters/tasks"    "$ecs"
    print_section "VPCs and NAT gateways" "$vpcs"
    print_section "IAM users and roles"   "$iam"
    print_section "Lambda functions"      "$lambda"

    printf "\n%s\n\n" "$SEPARATOR"
}

check_aws_account_connection_status
generate_report