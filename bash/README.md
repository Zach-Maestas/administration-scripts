# Bash Scripts

Shell scripts for Linux system administration, security monitoring, 
and cloud operations.

## Scripts

---

### failed_ssh_login_parser.sh
Parses `/var/log/auth.log` for failed SSH login attempts and generates 
a color-coded ranked threat report with risk classification.

**Usage:**
```bash
./failed_ssh_login_parser.sh [log_file_path]
./failed_ssh_login_parser.sh                    # defaults to /var/log/auth.log
./failed_ssh_login_parser.sh samples/auth_sample.log
```

**Sample Output:**
```
[2026-06-20 14:32:01] Processing log file...

======================================
RANK  IP ADDRESS      ATTEMPTS   RISK
--------------------------------------
1     192.168.1.105   47         HIGH
2     10.0.0.23       12         MEDIUM
3     172.16.0.8      5          LOW
======================================
Total unique IPs: 3

⚠️  HIGH RISK ALERT — Immediate attention required:
   -----------------------------------------------
     192.168.1.105 » 47 attempts

[2026-06-20 14:32:01] Report saved to ssh_parser_2026-06-20_143201.log
```

**Risk Thresholds:**
- HIGH — 20+ attempts
- MEDIUM — 10-19 attempts
- LOW — under 10 attempts

**Concepts demonstrated:**
- `set -euo pipefail` for safe script execution
- Local arrays for scoped high risk IP tracking
- ANSI color output with clean log file stripping via `tee` and `sed`
- Timestamped dual output to stdout and log file
- `grep`, `awk`, `sort`, `uniq` pipeline for log analysis

**Requirements:**
- Bash 4.0+
- Sample log files available in `samples/`

---

### dns-troubleshooter.sh
Checks DNS resolution, HTTP status, TLS certificate, and response times for a 
domain and prints a color-coded health report.

**Usage:**
```bash
./dns-troubleshooter.sh <domain>
./dns-troubleshooter.sh example.com
```

**Sample Output:**
```
Checking example.com...

================================================
DNS/HTTP Health Report — example.com
================================================
DNS Resolution:        ✓ 93.184.216.34
HTTP Status:           ✓ 200
HTTPS/TLS:             ✓ Sep 12 12:00:00 2026 GMT
TLS Issuer:            ✓ DigiCert Global G2 TLS RSA SHA256 2020 CA1
HTTP Response Time:    ✓ 0.213s
DNS Lookup Time (ms):  ✓ 13
================================================
Status: HEALTHY
================================================
```

**Status Classifications:**
- HEALTHY — all 6 checks pass
- DEGRADED — 1–4 checks fail
- UNHEALTHY — 5+ checks fail (domain likely fully down)

**Concepts demonstrated:**
- Function-based check pattern with a shared `validate_check` dispatcher
- `dig`, `curl`, and `openssl` for DNS, HTTP, and TLS introspection
- `set -euo pipefail` for safe script execution
- ANSI color output for pass/fail/status indicators
- `printf` column alignment for structured report formatting

**Requirements:**
- Bash 4.0+
- `dig` (dnsutils), `curl`, `openssl`

---

### system-health-check.sh
Collects CPU, memory, and disk metrics and prints a color-coded health report
with NORMAL / WARNING / CRITICAL status thresholds.

**Usage:**
```bash
./system-health-check.sh
```

**Sample Output:**
```
[2026-07-07 09:15:22] Running system health check...

================================================
System Health Report — web-01
2026-07-07 09:15:22
================================================

CPU Usage:
  Usage:          12%
  Status:         ✓ NORMAL

Memory Usage:
  Total:          16GiB
  Used:           7GiB
  Free:           9GiB
  Usage:          44%
  Status:         ✓ NORMAL

Disk Usage:
  Filesystem    Size    Used    Avail   Use%    Status
  -------------------------------------------------------
  /dev/sda1     100G    62G     38G     62%     ✓ NORMAL
  /dev/sdb1     500G    455G    45G     91%     ✗ CRITICAL

================================================
Overall Status:  ✗ CRITICAL
================================================
```

**Status Thresholds (per metric):**
- NORMAL — usage ≤ 80%
- WARNING — usage 81–90%
- CRITICAL — usage > 90%

**Concepts demonstrated:**
- `set -euo pipefail` for safe script execution
- Shared `get_status` helper parameterized by warn/crit thresholds
- `top`, `free --mega`, and `df -h` for CPU, memory, and disk introspection
- `awk` field extraction and virtual-filesystem exclusion (`tmpfs`, `overlay`)
- `read <<<` here-strings to unpack multi-value function returns
- Overall status derived by scanning per-section outputs for CRITICAL/WARNING
- ANSI color output for status indicators

**Requirements:**
- Bash 4.0+
- Linux with `top`, `free`, `df` available (procps + coreutils)

---

### service-health-monitor.sh
Checks the systemd active state of one or more services and prints a
color-coded health report with ACTIVE / INACTIVE / NOT FOUND status.

**Usage:**
```bash
./service-health-monitor.sh <service> [service...]
./service-health-monitor.sh nginx postgresql redis
```

**Sample Output:**
```
================================================
Service Health Report — web-01
2026-07-07 09:15:22
================================================

  Service              Status
  ----------------------------------------------
  nginx                ✓ ACTIVE
  postgresql           ✗ INACTIVE
  redis                ⚠ NOT FOUND

================================================
Overall Status: ✗ CRITICAL
================================================
```

**Status Classifications:**
- NORMAL — all services ACTIVE
- WARNING — at least one service NOT FOUND, none INACTIVE
- CRITICAL — at least one service INACTIVE (CRITICAL wins over WARNING)

**Concepts demonstrated:**
- `set -euo pipefail` for safe script execution
- `systemctl is-active --quiet` with exit-code branching (0 active, 4 missing)
- Overall-status escalation logic that prevents CRITICAL from being downgraded
- `printf` column alignment for structured report formatting
- ANSI color output for pass/fail/status indicators

**Requirements:**
- Bash 4.0+
- Linux with `systemd` (`systemctl` in PATH)

---

### aws-resource-audit.sh
Audits the caller's AWS account and prints a summary report of EC2, S3, RDS,
ECS, VPC/NAT, IAM, and Lambda resources, grouped by service with per-section
counts.

**Usage:**
```bash
./aws-resource-audit.sh
```

**Sample Output:**
```
[2026-07-07 09:15:22] AWS authentication success!

=======================================================
 AWS Resource Audit - 123456789012
 [2026-07-07 09:15:23]
=======================================================

EC2 instances (2):
  i-0abc123def456ghi7
  i-0jkl890mno123pqr4

S3 buckets (3):
  my-app-logs
  my-app-backups
  my-app-artifacts

RDS instances (1):
  my-app-prod-db

ECS clusters/tasks (3):
  my-app-cluster
    a1b2c3d4e5f6g7h8
    i9j0k1l2m3n4o5p6

VPCs and NAT gateways (3):
  vpc-0abc123def456
    nat-0ghi789jkl012

IAM users (2):
  ci-deployer
  admin

IAM roles (1):
  MyAppLambdaRole

Lambda functions (1):
  my-app-processor

=======================================================
```

**Concepts demonstrated:**
- `set -euo pipefail` for safe script execution
- Preflight authentication check via `aws sts get-caller-identity`
- One function per AWS service, composed by a shared `print_section` renderer
- JMESPath `--query` expressions for server-side filtering (e.g., excluding
  AWS-managed IAM roles)
- Parameter expansion `${var##*/}` to trim ARNs down to short identifiers
- `printf` column alignment for structured report formatting

**Requirements:**
- Bash 4.0+
- AWS CLI v2 configured with credentials (`aws configure`) that have read
  access to the audited services