# Administration Scripts

A collection of Bash and Python automation scripts for Linux administration, 
cloud operations, and security monitoring.

## Structure

- `bash/` — Shell scripts for system administration and security analysis
- `python/` — Python scripts for AWS automation via boto3

## Scripts

### Bash
| Script | Description |
|--------|-------------|
| failed_ssh_login_parser.sh | Parses auth.log for failed SSH attempts and generates a ranked threat report |
| dns_http_troubleshooter.sh | Checks DNS resolution, HTTP status, and TLS certificate validity for a domain |
| system_health_check.sh | Reports CPU, memory, and disk usage with configurable thresholds |
| service_health_monitor.sh | Monitors systemd services and restarts any that are down |
| aws_resource_audit.sh | Audits AWS S3 and IAM resources for common misconfigurations |

### Python
| Script | Description |
|--------|-------------|
| Coming soon | boto3 automation scripts |

## Requirements
- Bash 4.0+
- AWS CLI (for aws_resource_audit.sh)