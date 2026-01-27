---
description: >-
  Scan your Wheels application for security vulnerabilities and potential
  security issues with automated analysis and reporting.
---

# Security Scan

## Overview

The `wheels security scan` command performs comprehensive security analysis of your Wheels application, identifying potential vulnerabilities, security misconfigurations, and code patterns that could pose security risks.

## Usage

```bash
wheels security scan [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--path` | string | Path to scan (default: current directory) |
| `--fix` | boolean | Attempt to fix issues automatically |
| `--report` | string | Generate report format (`console`, `json`, `html`) |
| `--severity` | string | Minimum severity to report (`low`, `medium`, `high`, `critical`) |
| `--output` | string | Output file for report (optional) |

## Examples

### Basic Security Scan
```bash
wheels security scan
```
**Output:**
```
🔍 Scanning for security issues...

Scan complete!
Summary:
Critical: 11
High: 107

Security Scan Results
====================
Path: C:\Users\Hp\cli_testingapp\db_app\
Date: 2026-01-26 15:27:46

Summary:
Critical: 2
High: 5
Medium: 12
Low: 8

Issues Found:
❌ [CRITICAL] SQL Injection vulnerability in /app/controllers/Users.cfc:45
❌ [CRITICAL] Hardcoded password in /config/settings.cfm:23
⚠️  [HIGH] Missing CSRF protection in /app/controllers/Admin.cfc:12
⚠️  [HIGH] Unvalidated redirect in /app/controllers/Auth.cfc:67
ℹ️  [MEDIUM] Session timeout not configured
ℹ️  [MEDIUM] Debug mode enabled in production config

Run with --fix to attempt automatic fixes.
```

### Scan with Automatic Fixes
```bash
wheels security scan --fix
```
**Output:**
```
🔧 Scanning and fixing security issues...

Auto-fixing issues:
✅ [FIXED] Added CSRF protection to Admin controller
✅ [FIXED] Disabled debug mode in production config
✅ [FIXED] Added session timeout configuration
⚠️  [MANUAL] SQL injection requires manual review
⚠️  [MANUAL] Hardcoded password requires manual replacement

3 issues fixed automatically, 2 require manual intervention.
```

### Generate HTML Report
```bash
wheels security scan --report=html --output=security-report.html
```

### Scan Specific Path
```bash
wheels security scan --path=app/controllers --severity=high
```

### JSON Report for CI/CD
```bash
wheels security scan --report=json --output=security-results.json --severity=medium
```

## Security Checks

### Critical Severity Issues

#### SQL Injection Vulnerabilities
- **Raw SQL queries** without proper parameterization
- **Dynamic query building** using string concatenation
- **Unsafe use of variables** in WHERE clauses

**Example Detection:**
```cfm
// VULNERABLE - Will be flagged
users = model("User").findAll(where="name = '#params.name#'");

// SECURE - Recommended fix
users = model("User").findAll(where="name = :name", name=params.name);
```

#### Authentication Bypass
- **Missing authentication filters** on sensitive actions
- **Weak password policies**
- **Session management issues**

#### Code Injection
- **Unsafe eval() usage**
- **Dynamic component creation** with user input
- **Unsafe file includes**

### High Severity Issues

#### Cross-Site Request Forgery (CSRF)
- **Missing CSRF protection** in controllers
- **Forms without authenticity tokens**
- **State-changing GET requests**

**Example Detection:**
```cfm
// VULNERABLE - Will be flagged
component extends="Controller" {
    function delete() {
        model("User").deleteByKey(params.key);
    }
}

// SECURE - Recommended fix
component extends="Controller" {
    function config() {
        protectsFromForgery(); // Add this
    }

    function delete() {
        model("User").deleteByKey(params.key);
    }
}
```

#### Cross-Site Scripting (XSS)
- **Unescaped output** in views
- **Raw HTML rendering** without sanitization
- **User input displayed** without validation

#### Information Disclosure
- **Error messages with sensitive data**
- **Debug information** in production
- **Directory listing enabled**

### Medium Severity Issues

#### Configuration Issues
- **Debug mode enabled** in production
- **Verbose error reporting** enabled
- **Missing security headers**
- **Weak session configuration**

#### Access Control
- **Missing authorization checks**
- **Overly permissive file permissions**
- **Weak password requirements**

### Low Severity Issues

#### Code Quality
- **Commented-out security code**
- **TODO comments** about security
- **Deprecated security functions**

## Report Formats

### Console Output (Default)
Human-readable output with color-coded severity levels and actionable recommendations.

### JSON Report
```json
{
  "scanDate": "2025-09-16T10:30:00Z",
  "scanPath": "/path/to/project",
  "summary": {
    "totalIssues": 27,
    "severityCounts": {
      "critical": 2,
      "high": 5,
      "medium": 12,
      "low": 8
    }
  },
  "issues": [
    {
      "id": "SQL_INJECTION_001",
      "severity": "critical",
      "title": "SQL Injection vulnerability",
      "description": "Raw SQL query without parameterization",
      "file": "/app/controllers/Users.cfc",
      "line": 45,
      "code": "users = model('User').findAll(where=\"name = '#params.name#'\");",
      "recommendation": "Use parameterized queries or ORM methods",
      "fixable": false,
      "cwe": "CWE-89"
    }
  ]
}
```

### HTML Report
Interactive HTML report with:
- **Executive summary** with charts
- **Issue categorization** by severity and type
- **Code snippets** with highlighted vulnerabilities
- **Remediation guidance** with examples
- **Compliance mapping** to security standards

## Automatic Fixes

### What Can Be Auto-Fixed

#### CSRF Protection
```cfm
// BEFORE
component extends="Controller" {
    function create() {
        // No CSRF protection
    }
}

// AFTER (auto-fixed)
component extends="Controller" {
    function config() {
        protectsFromForgery(); // Added automatically
    }

    function create() {
        // Now protected against CSRF
    }
}
```

#### Debug Mode Configuration
```cfm
// BEFORE - /config/production/settings.cfm
set(showErrorInformation=true);  // Dangerous in production

// AFTER (auto-fixed)
set(showErrorInformation=false); // Secured automatically
```

#### Session Security
```cfm
// BEFORE - /config/settings.cfm
// Missing session security

// AFTER (auto-fixed)
set(sessionTimeout=30);          // Added timeout
set(sessionCookieSecure=true);   // Secure cookies
set(sessionCookieHttpOnly=true); // HTTP-only cookies
```

### What Requires Manual Review

- **SQL injection vulnerabilities** - Require code analysis
- **Hardcoded credentials** - Need secure replacement
- **Business logic flaws** - Require domain knowledge
- **Complex XSS issues** - Need context-aware fixes

## Integration with CI/CD

### GitHub Actions
```yaml
- name: Security Scan
  run: |
    wheels security scan --report=json --output=security.json --severity=high
    if [ -s security.json ]; then
      echo "Security issues found"
      cat security.json
      exit 1
    fi
```

### Exit Codes
| Code | Meaning |
|------|---------|
| 0 | No security issues found |
| 1 | Critical or high severity issues found |
| 2 | Medium severity issues found |
| 3 | Scan error occurred |

## Configuration

### Custom Security Rules
Create `/config/security-scan.cfm` to customize scanning:

```cfm
<cfscript>
// Custom security scan configuration
set(securityScan = {
    // Enable/disable specific checks
    sqlInjectionCheck = true,
    csrfCheck = true,
    xssCheck = true,
    authenticationCheck = true,

    // Custom severity levels
    customRules = {
        "hardcodedPasswords" = "critical",
        "debugModeProduction" = "high",
        "missingHttpsRedirect" = "medium"
    },

    // Excluded paths
    excludePaths = [
        "/tests/",
        "/vendor/",
        "/build/"
    ],

    // File patterns to scan
    includePatterns = [
        "*.cfc",
        "*.cfm",
        "*.cfml"
    ]
});
</cfscript>
```

## Best Practices

### Regular Scanning
```bash
# Weekly security scan
wheels security scan --report=html --output=weekly-security-report.html

# Pre-deployment scan
wheels security scan --severity=high --fix
```

### Team Integration
```bash
# Generate team report
wheels security scan --report=html --output=team-security-$(date +%Y%m%d).html

# Share results
git add team-security-*.html
git commit -m "Security scan results"
```

## Troubleshooting

### Common Issues

**1. "No issues found" but security concerns exist**
- Check `--severity` setting (try `--severity=low`)
- Verify scan path includes application code
- Review excluded patterns in configuration

**2. "Permission denied" errors**
- Ensure read access to all scanned files
- Check file system permissions
- Run with appropriate user privileges

**3. "False positives" in results**
- Review custom rules configuration
- Add specific exclusions for known safe code
- Use `--path` to focus on specific areas

## Security Standards Compliance

The security scan checks for compliance with:
- **OWASP Top 10** - Web application security risks
- **CWE** - Common Weakness Enumeration
- **NIST** - National Institute of Standards guidelines
- **SANS Top 25** - Most dangerous software errors

## Related Commands

- [`wheels test`](../test/test-run.md) - Run application tests
- [`wheels analyze`](../analysis/analyze-code.md) - Code quality analysis
- [`wheels deps`](../core/deps.md) - Dependency vulnerability scan

## Additional Resources

- [Wheels Security Guide](../../handling-requests-with-controllers/verification.md)
- [CSRF Protection Documentation](../../handling-requests-with-controllers/request-handling.md)
- [Authentication Patterns](../../database-interaction-through-models/README.md)