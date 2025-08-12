# wheels security (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Base command for security management and vulnerability scanning.

## Synopsis

```bash
wheels security [subcommand] [options]
```

## Description

The `wheels security` command provides comprehensive security tools for Wheels applications. It scans for vulnerabilities, checks security configurations, and helps implement security best practices.

## Subcommands

| Command | Description |
|---------|-------------|
| `scan` | Scan for security vulnerabilities |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Direct Usage

When called without subcommands, performs a quick security check:

```bash
wheels security
```

Output:
```
Wheels Security Overview
=======================

Last Scan: 2024-01-15 10:30:45
Status: 3 issues found

Critical: 0
High:     1 
Medium:   2
Low:      0

Vulnerabilities:
- [HIGH] SQL Injection risk in UserModel.cfc:45
- [MEDIUM] Missing CSRF protection on /admin routes
- [MEDIUM] Outdated dependency: cfml-jwt (2.1.0 → 3.0.0)

Run 'wheels security scan' for detailed analysis
```

## Examples

### Quick security check
```bash
wheels security
```

### Check security status
```bash
wheels security --status
```

### Generate security report
```bash
wheels security --report
```

### Check specific area
```bash
wheels security --check=dependencies
```

## Security Areas

### Code Security
- SQL injection detection
- XSS vulnerability scanning
- Path traversal checks
- Command injection risks

### Configuration
- Security headers
- CORS settings
- Authentication config
- Session management

### Dependencies
- Vulnerable packages
- Outdated libraries
- License compliance
- Supply chain risks

### Infrastructure
- SSL/TLS configuration
- Port exposure
- File permissions
- Environment secrets

## Security Configuration

Configure via `.wheels-security.json`:

```json
{
  "security": {
    "scanOnCommit": true,
    "autoFix": false,
    "severity": "medium",
    "ignore": [
      {
        "rule": "sql-injection",
        "file": "legacy/*.cfc",
        "reason": "Legacy code, sandboxed"
      }
    ],
    "checks": {
      "dependencies": true,
      "code": true,
      "configuration": true,
      "infrastructure": true
    }
  }
}
```

## Security Policies

### Define Policies
Create `.wheels-security-policy.yml`:

```yaml
policies:
  - name: "No Direct SQL"
    description: "Prevent direct SQL execution"
    severity: "high"
    rules:
      - pattern: "queryExecute\\(.*\\$.*\\)"
        message: "Use parameterized queries"
  
  - name: "Secure Headers"
    description: "Require security headers"
    severity: "medium"
    headers:
      - "X-Frame-Options"
      - "X-Content-Type-Options"
      - "Content-Security-Policy"
```

### Policy Enforcement
```bash
# Check policy compliance
wheels security --check-policy

# Enforce policies (fail on violation)
wheels security --enforce-policy
```

## Integration

### Git Hooks
`.git/hooks/pre-commit`:
```bash
#!/bin/bash
wheels security scan --severity=high --fail-on-issues
```

### CI/CD Pipeline
```yaml
- name: Security scan
  run: |
    wheels security scan --format=sarif
    wheels security --upload-results
```

### IDE Integration
```json
{
  "wheels.security": {
    "realTimeScan": true,
    "showInlineWarnings": true
  }
}
```

## Security Headers

### Check Headers
```bash
wheels security headers --check
```

### Configure Headers
```cfml
// Application.cfc
this.securityHeaders = {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "Strict-Transport-Security": "max-age=31536000",
    "Content-Security-Policy": "default-src 'self'"
};
```

## Dependency Scanning

### Check Dependencies
```bash
wheels security deps
```

### Update Vulnerable Dependencies
```bash
wheels security deps --fix
```

### License Compliance
```bash
wheels security licenses --allowed=MIT,Apache-2.0
```

## Security Fixes

### Automatic Fixes
```bash
# Fix auto-fixable issues
wheels security fix

# Fix specific issue types
wheels security fix --type=headers,csrf
```

### Manual Fixes
The command provides guidance:
```
Issue: SQL Injection Risk
File: /models/User.cfc:45
Fix: Replace direct SQL with parameterized query

Current:
query = "SELECT * FROM users WHERE id = #arguments.id#";

Suggested:
queryExecute(
    "SELECT * FROM users WHERE id = :id",
    { id: arguments.id }
);
```

## Security Reports

### Generate Reports
```bash
# HTML report
wheels security scan --report=html

# JSON report for tools
wheels security scan --format=json

# SARIF for GitHub
wheels security scan --format=sarif
```

### Report Contents
- Executive summary
- Detailed findings
- Remediation steps
- Compliance status
- Trend analysis

## Compliance

### Standards
Check compliance with standards:
```bash
# OWASP Top 10
wheels security compliance --standard=owasp-top10

# PCI DSS
wheels security compliance --standard=pci-dss

# Custom standard
wheels security compliance --standard=./company-standard.yml
```

## Security Monitoring

### Continuous Monitoring
```bash
# Start monitoring
wheels security monitor --start

# Check monitor status
wheels security monitor --status

# View alerts
wheels security monitor --alerts
```

### Alert Configuration
```json
{
  "monitoring": {
    "alerts": {
      "email": "security@example.com",
      "slack": "https://hooks.slack.com/...",
      "severity": "high"
    }
  }
}
```

## Security Best Practices

1. **Regular Scans**: Schedule automated scans
2. **Fix Quickly**: Address high-severity issues immediately
3. **Update Dependencies**: Keep libraries current
4. **Security Training**: Educate development team
5. **Defense in Depth**: Layer security measures

## Common Vulnerabilities

### SQL Injection
```cfml
// Vulnerable
query = "SELECT * FROM users WHERE id = #url.id#";

// Secure
queryExecute(
    "SELECT * FROM users WHERE id = :id",
    { id: { value: url.id, cfsqltype: "integer" } }
);
```

### XSS
```cfml
// Vulnerable
<cfoutput>#form.userInput#</cfoutput>

// Secure
<cfoutput>#encodeForHTML(form.userInput)#</cfoutput>
```

## Emergency Response

### Incident Detection
```bash
# Check for compromise indicators
wheels security incident --check

# Generate incident report
wheels security incident --report
```

### Lockdown Mode
```bash
# Enable security lockdown
wheels security lockdown --enable

# Disable after resolution
wheels security lockdown --disable
```

## Notes

- Security scans may take time on large codebases
- Some checks require running application
- False positives should be documented
- Regular updates improve detection accuracy

## See Also

- [wheels security scan](security-scan.md) - Detailed security scanning
- [wheels analyze security](../analysis/analyze-security.md) - Security analysis (deprecated)
- [Security Best Practices](../../security/best-practices.md)
- [OWASP Guidelines](https://owasp.org/)