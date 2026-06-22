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