# security scan

Scans your CFWheels application for security vulnerabilities and provides remediation recommendations.

## Usage

```bash
wheels security scan [--level=<level>] [--fix] [--report=<file>] [--exclude=<patterns>]
```

## Parameters

- `--level` - (Optional) Scan level: `basic`, `standard`, `comprehensive`. Default: `standard`
- `--fix` - (Optional) Automatically fix safe issues
- `--report` - (Optional) Save detailed report to file
- `--exclude` - (Optional) Comma-separated patterns to exclude from scan

## Description

The `security scan` command performs comprehensive security analysis of your CFWheels application, checking for:

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

### Comprehensive scan with auto-fix
```bash
wheels security scan --level=comprehensive --fix
```

### Generate security report
```bash
wheels security scan --report=security-audit.html
```

### Exclude test files
```bash
wheels security scan --exclude="tests/*,temp/*"
```

### Quick basic scan
```bash
wheels security scan --level=basic
```

## Scan Levels

### Basic
- Configuration checks
- Known vulnerability patterns
- Dependency scanning

### Standard (Default)
- All basic checks
- Code analysis for common vulnerabilities
- Authentication/authorization review
- Input validation checks

### Comprehensive
- All standard checks
- Deep code flow analysis
- Third-party integration security
- Performance impact analysis
- Custom vulnerability rules

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
    wheels security scan --level=standard --report=scan.json
    if [ $? -ne 0 ]; then
      echo "Security vulnerabilities found"
      exit 1
    fi
```

### Pre-commit Hook
```bash
#!/bin/bash
wheels security scan --level=basic
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