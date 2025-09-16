---
description: >-
  Security commands for scanning, analyzing, and hardening your Wheels
  application against vulnerabilities and security threats.
---

# Security Commands

Wheels provides comprehensive security tools to help identify vulnerabilities, enforce security best practices, and maintain a secure application throughout development and deployment.

## Available Commands

### Core Security Commands
- [`wheels security scan`](./security-scan.md) - Scan for security vulnerabilities

## Overview

Security is a critical aspect of web application development. The Wheels security commands help you:

- **Identify Vulnerabilities**: Automated scanning for common security issues
- **Enforce Best Practices**: Check compliance with security standards
- **Fix Issues Automatically**: Auto-repair common security misconfigurations
- **Generate Reports**: Create detailed security reports for teams and compliance
- **Integrate with CI/CD**: Automated security testing in your build pipeline

## Quick Start

### Basic Security Assessment
```bash
# Scan your entire application
wheels security scan

# Focus on critical issues only
wheels security scan --severity=critical

# Generate detailed HTML report
wheels security scan --report=html --output=security-report.html
```

## Security Checks

### Vulnerability Categories

#### Critical Issues
- **SQL Injection** - Database query vulnerabilities
- **Authentication Bypass** - Missing or weak authentication
- **Code Injection** - Unsafe code execution vulnerabilities
- **Hardcoded Credentials** - Passwords, keys, or secrets in code

#### High Priority Issues
- **Cross-Site Request Forgery (CSRF)** - Missing request validation
- **Cross-Site Scripting (XSS)** - Unescaped user input
- **Information Disclosure** - Sensitive data exposure
- **Insecure Direct Object References** - Missing authorization

#### Medium Priority Issues
- **Security Misconfiguration** - Unsafe application settings
- **Weak Session Management** - Session security issues
- **Missing Security Headers** - HTTP security headers
- **Input Validation Issues** - Insufficient input checking

#### Low Priority Issues
- **Code Quality Issues** - Security-related code smells
- **Documentation Gaps** - Missing security documentation
- **Deprecated Functions** - Use of outdated security methods

## Framework-Specific Security

### Wheels Security Features
The security commands understand and check for proper usage of Wheels security features:

#### CSRF Protection
```cfm
// Checked: CSRF protection enabled
component extends="Controller" {
    function config() {
        protectsFromForgery(); ✅
    }
}

// Flagged: Missing CSRF protection
component extends="Controller" {
    function create() {
        // State-changing action without protection ❌
    }
}
```

#### Model Security
```cfm
// Checked: Proper parameter usage
users = model("User").findAll(where="name = :name", name=params.name); ✅

// Flagged: SQL injection risk
users = model("User").findAll(where="name = '#params.name#'"); ❌
```

#### Configuration Security
```cfm
// Checked: Production-safe settings
set(showErrorInformation=false); ✅
set(sendEmailOnError=true); ✅

// Flagged: Debug mode in production
set(showErrorInformation=true); ❌
```

## Integration Workflows

### Development Workflow
```bash
# Pre-commit security check
wheels security scan --severity=high --fix

# If issues found, review and fix manually
git add -A
git commit -m "Security fixes applied"
```

### CI/CD Integration
```bash
# In your build pipeline
wheels security scan --report=json --output=security-results.json --severity=medium

# Fail build on security issues
if [ -s security-results.json ]; then
  echo "Security issues found - failing build"
  exit 1
fi
```

### Team Reporting
```bash
# Weekly security report
wheels security scan --report=html --output="security-report-$(date +%Y%m%d).html"

# Share with team
echo "Weekly security scan complete. Report: security-report-$(date +%Y%m%d).html"
```

## Best Practices

### Regular Security Scanning
1. **Daily Development**: Quick scans during active development
2. **Pre-commit**: Automated scans before code commits
3. **CI/CD Pipeline**: Comprehensive scans in automated builds
4. **Weekly Reviews**: Detailed security reports for team review
5. **Release Validation**: Security verification before deployments

### Security Configuration
1. **Environment-Specific**: Different security rules for dev/prod
2. **Custom Rules**: Tailored security checks for your application
3. **Exclusion Patterns**: Skip vendor code and test files
4. **Severity Tuning**: Adjust sensitivity based on project needs

### Team Practices
1. **Security Training**: Educate team on common vulnerabilities
2. **Code Reviews**: Include security review in code review process
3. **Documentation**: Maintain security guidelines and procedures
4. **Incident Response**: Plan for addressing security issues

## Security Standards

### Compliance Coverage
The security commands help ensure compliance with:
- **OWASP Top 10** - Web application security risks
- **CWE Top 25** - Most dangerous software errors
- **NIST Cybersecurity Framework** - Security best practices
- **PCI DSS** - Payment card security requirements (relevant checks)
- **GDPR** - Data protection requirements (data handling checks)

### Security Frameworks
- **Defense in Depth** - Multiple layers of security controls
- **Secure by Design** - Security built into development process
- **Zero Trust** - Never trust, always verify approach
- **Risk-Based Security** - Focus on highest-impact vulnerabilities

## Reporting and Analytics

### Report Types
1. **Console Output** - Quick feedback during development
2. **JSON Reports** - Machine-readable for automation
3. **HTML Reports** - Detailed reports for human review
4. **Executive Summary** - High-level security overview

### Metrics Tracking
- **Vulnerability Trends** - Track security improvement over time
- **Fix Rates** - Monitor how quickly issues are resolved
- **New Issue Detection** - Identify newly introduced vulnerabilities
- **Compliance Scores** - Measure adherence to security standards

## Advanced Features

### Custom Security Rules
Create application-specific security checks:

```cfm
// /config/security-rules.cfm
customSecurityRules = {
    // Check for specific business logic vulnerabilities
    "adminPanelAccess": {
        pattern: "admin.*\.cfc",
        check: "authentication",
        severity: "critical"
    },

    // Check for data privacy compliance
    "personalDataHandling": {
        pattern: ".*user.*\.cfc",
        check: "dataProtection",
        severity: "high"
    }
};
```

### Integration APIs
Programmatic access to security scanning:

```cfm
// In your application
securityService = new SecurityService();
results = securityService.scan(
    path = "/app",
    severity = "medium",
    outputFormat = "json"
);

// Process results
for (issue in results.issues) {
    if (issue.severity == "critical") {
        // Alert security team
        sendSecurityAlert(issue);
    }
}
```

## Performance Considerations

### Scan Optimization
- **Incremental Scanning** - Only scan changed files
- **Parallel Processing** - Faster scanning of large codebases
- **Caching Results** - Skip unchanged files in subsequent scans
- **Selective Scanning** - Focus on high-risk areas first

### Resource Usage
- **Memory Efficient** - Handles large projects without memory issues
- **CPU Optimization** - Efficient pattern matching and analysis
- **Disk I/O** - Minimized file system operations
- **Network Resources** - Efficient vulnerability database updates

## Troubleshooting

### Common Issues
1. **False Positives** - Configure exclusions or custom rules
2. **Performance Issues** - Use selective scanning or increase resources
3. **Integration Problems** - Check CI/CD configuration and permissions
4. **Report Generation** - Verify output paths and file permissions

### Getting Help
1. **Verbose Output** - Use detailed logging for debugging
2. **Documentation** - Comprehensive guides and examples
3. **Community Support** - Active community forums and resources
4. **Professional Support** - Enterprise support options available

## Related Documentation

- [Request Handling Security](../../handling-requests-with-controllers/request-handling.md)
- [Database Security](../../database-interaction-through-models/README.md)
- [Configuration Security](../../working-with-wheels/configuration-and-defaults.md)
- [Testing Security](../../working-with-wheels/testing-your-application.md)