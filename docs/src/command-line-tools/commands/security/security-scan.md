# security scan (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Scans your Wheels application for security vulnerabilities and provides remediation recommendations.

## Usage

```bash
wheels security scan [path] [--fix] [--report=<format>] [--severity=<level>] [--output=<file>]
```

## Parameters

- `path` - (Optional) Path to scan. Default: current directory (`.`)
- `--fix` - (Optional) Attempt to fix issues automatically
- `--report` - (Optional) Report format: `console`, `json`, `html`. Default: `console`
- `--severity` - (Optional) Minimum severity to report: `low`, `medium`, `high`, `critical`. Default: `medium`
- `--output` - (Optional) Output file for report

## Description

The `security scan` command performs comprehensive security analysis of your Wheels application, checking for:

- SQL injection vulnerabilities
- Cross-site scripting (XSS) risks
- Cross-site request forgery (CSRF) issues
- Insecure direct object references
- Security misconfigurations
- Outdated dependencies with known vulnerabilities
- Weak authentication patterns
- Information disclosure risks

## Examples

### Standard security scan
```bash
wheels security scan
```

### Scan with auto-fix
```bash
wheels security scan --fix
```

### Generate HTML security report
```bash
wheels security scan --report=html --output=security-audit.html
```

### Scan specific directory with high severity only
```bash
wheels security scan app/models --severity=high
```

### JSON report for CI/CD integration
```bash
wheels security scan --report=json --output=scan-results.json
```

## Severity Levels

The `--severity` parameter filters which issues are reported:

### Low
- Code style issues that could lead to vulnerabilities
- Missing best practices
- Informational findings

### Medium (Default)
- Potential security issues requiring review
- Missing security headers
- Weak configurations

### High
- Confirmed vulnerabilities with moderate impact
- Authentication/authorization issues
- Data validation problems

### Critical
- Severe vulnerabilities requiring immediate attention
- SQL injection risks
- Remote code execution possibilities

## Output

```
Security Scan Results
====================

Scanning application...
✓ Configuration files
✓ Controllers (15 files)
✓ Models (8 files)
✓ Views (23 files)
✗ Dependencies (2 issues)

CRITICAL: 1 issue found
-----------------------
1. SQL Injection Risk
   File: /app/models/User.cfc
   Line: 45
   Code: findOne(where="id = #params.id#")
   Fix: Use parameterized queries
   
HIGH: 3 issues found
--------------------
1. XSS Vulnerability
   File: /app/views/users/show.cfm
   Line: 12
   Code: <h1>#user.name#</h1>
   Fix: Use htmlEditFormat() or encodeForHTML()

2. Missing CSRF Token
   File: /app/views/users/edit.cfm
   Line: 8
   Fix: Add authenticityToken() to form

3. Outdated Dependency
   Package: jackson-databind
   Version: 2.9.0 (CVE-2019-12345)
   Fix: Update to version 2.14.0 or higher

MEDIUM: 5 issues found
LOW: 12 issues found

Summary:
- Critical: 1
- High: 3
- Medium: 5
- Low: 12
- Total: 21 vulnerabilities

Recommended Actions:
1. Fix all CRITICAL issues immediately
2. Address HIGH issues before deployment
3. Plan remediation for MEDIUM issues
4. Review LOW issues for false positives
```

## Auto-Fix Feature

The `--fix` flag automatically resolves safe issues:

```bash
wheels security scan --fix

Auto-fixing security issues...
✓ Added htmlEditFormat() to 3 output statements
✓ Added CSRF tokens to 2 forms
✓ Updated .htaccess security headers
✗ Cannot auto-fix: SQL injection (requires manual review)

Fixed 5 of 8 fixable issues
Manual intervention required for 3 issues
```

## Report Formats

### HTML Report
```bash
wheels security scan --report=security-report.html
```
Generates interactive HTML report with:
- Executive summary
- Detailed findings with code snippets
- Remediation steps
- Compliance mapping (OWASP, CWE)

### JSON Report
```bash
wheels security scan --report=security-report.json
```
Machine-readable format for CI/CD integration

## Integration

### CI/CD Pipeline
```yaml
# Example GitHub Actions
- name: Security Scan
  run: |
    wheels security scan --severity=medium --report=json --output=scan.json
    if [ $? -ne 0 ]; then
      echo "Security vulnerabilities found"
      exit 1
    fi
```

### Pre-commit Hook
```bash
#!/bin/bash
wheels security scan --severity=high
if [ $? -ne 0 ]; then
  echo "Commit blocked: Security issues detected"
  exit 1
fi
```

## Notes

- Scans are performed locally; no code is sent externally
- False positives can be suppressed with inline comments
- Regular scanning is recommended as part of development workflow
- Keep scan rules updated with `wheels deps update`
- Some fixes require manual review to ensure functionality