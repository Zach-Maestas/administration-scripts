#!/bin/bash

# aws-resource-audit.sh
# Audits the caller's AWS account and prints a summary report of EC2, S3, RDS,
# ECS, VPC/NAT, IAM, and Lambda resources
# Usage: ./aws-resource-audit.sh

set -euo pipefail

check_aws_account_connection_status () {
    # capture the aws CLI exit code without tripping set -e so we can print a
    # friendly failure message before bailing out
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
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --output text
}

get_s3_buckets () {
    aws s3api list-buckets --query "Buckets[*].[Name]" --output text
}

get_rds_instances () {
    aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier]" --output text
}

get_ecs_clusters_and_tasks () {
    local clusters cluster cluster_name tasks task_arn
    clusters=$(aws ecs list-clusters --query 'clusterArns[*]' --output text) || return 0

    [ -z "$clusters" ] && return 0

    # print each cluster's short name followed by its running task IDs indented beneath it;
    # cluster and task ARNs are stripped to their trailing identifier via ${var##*/}
    for cluster in $clusters; do
        cluster_name="${cluster##*/}"
        tasks=$(aws ecs list-tasks --cluster "$cluster" --query 'taskArns[*]' --output text) || continue
        printf '%s\n' "$cluster_name"
        if [ -n "$tasks" ]; then
            for task_arn in $tasks; do
                printf '  %s\n' "${task_arn##*/}"
            done
        else
            printf '  (No tasks)\n'
        fi
    done
}

get_vpcs_and_nat_gateways () {
    local vpcs all_nat_gateways vpc vpc_nats nat_id

    vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text) || return 0
    [ -z "$vpcs" ] && return 0

    all_nat_gateways=$(aws ec2 describe-nat-gateways \
        --query 'NatGateways[*].[VpcId,NatGatewayId]' \
        --output text) || true

    # for each VPC, print its ID then filter the pre-fetched NAT gateway list to find only
    # gateways belonging to that VPC, printing each indented beneath it
    for vpc in $vpcs; do
        printf '%s\n' "$vpc"
        vpc_nats=$(printf '%s\n' "$all_nat_gateways" | grep "^$vpc" | awk '{print $2}')
        if [ -n "$vpc_nats" ]; then
            for nat_id in $vpc_nats; do
                printf '  %s\n' "$nat_id"
            done
        else
            printf '  (No NAT Gateways)\n'
        fi
    done
}

get_iam_users () {
    aws iam list-users --query "Users[*].UserName" --output text | tr '\t' '\n'
}

get_iam_roles () {
    # skip AWS-managed service-linked roles (names prefixed with "AWS") so the
    # report only surfaces roles created by this account
    aws iam list-roles --query 'Roles[?!starts_with(RoleName, `AWS`)].RoleName' --output text | tr '\t' '\n'
}

get_lambda_functions () {
    # lambda is region-scoped; audit only the primary region to keep the call
    # count bounded — extend this list if the account uses multiple regions
    local region fns
    region="us-east-1"

    fns=$(aws lambda list-functions --region "$region" --query 'Functions[*].FunctionName' --output text)
    [ -z "$fns" ] && return 0
    printf '%s\n' "$fns" | tr '\t' '\n'
}

SEPARATOR="$(printf '=%.0s' {1..55})"

print_section () {
    local label="$1"
    local items="$2"
    local count=0
    # count lines only when items is non-empty; tr strips whitespace from wc output
    if [ -n "$items" ]; then
        count=$(printf '%s\n' "$items" | wc -l | tr -d ' ')
    fi

    printf "\n%s (%s):\n" "$label" "$count"
    # indent each item by two spaces for readability
    if [ -n "$items" ]; then
        printf '%s\n' "$items" | sed 's/^/  /'
    fi
}

generate_report () {
    local account_id timestamp
    account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local ec2 s3 rds ecs vpcs iam_users iam_roles lambda
    ec2=$(get_ec2_instances)
    s3=$(get_s3_buckets)
    rds=$(get_rds_instances)
    ecs=$(get_ecs_clusters_and_tasks)
    vpcs=$(get_vpcs_and_nat_gateways)
    iam_users=$(get_iam_users)
    iam_roles=$(get_iam_roles)
    lambda=$(get_lambda_functions)

    printf "\n%s\n" "$SEPARATOR"
    printf " AWS Resource Audit - %s \n [%s]\n" "$account_id" "$timestamp"
    printf "%s\n" "$SEPARATOR"

    print_section "EC2 instances"         "$ec2"
    print_section "S3 buckets"            "$s3"
    print_section "RDS instances"         "$rds"
    print_section "ECS clusters/tasks"    "$ecs"
    print_section "VPCs and NAT gateways" "$vpcs"
    print_section "IAM users"             "$iam_users"
    print_section "IAM roles"             "$iam_roles"
    print_section "Lambda functions"      "$lambda"

    printf "\n%s\n\n" "$SEPARATOR"
}

check_aws_account_connection_status
generate_report