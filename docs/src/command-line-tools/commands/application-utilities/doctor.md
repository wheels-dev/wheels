# wheels doctor (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Run comprehensive health checks on your Wheels application.

## Synopsis

```bash
wheels doctor [verbose=<boolean>]
```

## Description

The `doctor` command performs a series of health checks on your Wheels application, identifying configuration issues, missing dependencies, and potential problems. It's like a medical checkup for your application.

## Options

### verbose
- **Type**: Boolean
- **Default**: false
- **Description**: Show detailed diagnostic information including passed checks

## Examples

### Basic Health Check

```bash
wheels doctor
```

Output when issues are found:
```
Wheels Application Health Check
======================================================================

Issues Found (2):
  ✗ Missing critical directory: app/helpers
  ✗ Database configuration not found

Warnings (3):
  ⚠ Missing recommended directory: tests
  ⚠ No database migrations found
  ⚠ No .gitignore file (sensitive files may be committed)

======================================================================
Health Status: CRITICAL
Found 2 critical issues that need immediate attention.

Recommendations:
  • Configure your database connection in config/settings.cfm
  • Run 'wheels g app' to create missing directories
  • Add tests to improve code quality and reliability
```

### Verbose Output

```bash
wheels doctor verbose=true
```

Shows all checks including passed ones:
```
Wheels Application Health Check
======================================================================

Issues Found (1):
  ✗ Missing critical directory: app/helpers

Warnings (2):
  ⚠ No tests found
  ⚠ Modules not installed (run 'box install')

Checks Passed (15):
  ✓ Directory exists: app
  ✓ Directory exists: app/controllers
  ✓ Directory exists: app/models
  ✓ Directory exists: app/views
  ✓ Directory exists: config
  ✓ Directory exists: public
  ✓ File exists: Application.cfc
  ✓ File exists: config/routes.cfm
  ✓ File exists: config/settings.cfm
  ✓ Application name is configured
  ✓ Session management is configured
  ✓ Routes are configured
  ✓ Write permission OK: db/migrate
  ✓ CFWheels dependency declared
  ✓ .gitignore file exists

======================================================================
Health Status: WARNING
Found 2 warnings that should be addressed.
```

## Health Checks Performed

### Required Directories
Checks for critical directories:
- `app/` - Application root
- `app/controllers/` - Controllers
- `app/models/` - Models  
- `app/views/` - Views
- `config/` - Configuration
- `public/` - Public assets

### Recommended Directories
Checks for optional but recommended:
- `db/` - Database files
- `db/migrate/` - Migrations
- `tests/` - Test suite

### Required Files
Verifies essential files exist:
- `Application.cfc` - CF application file
- `config/routes.cfm` - Route definitions
- `config/settings.cfm` - Application settings

### Recommended Files
Checks for best practice files:
- `box.json` - Package definition
- `.gitignore` - Git ignore rules
- `README.md` - Documentation

### Configuration Checks
Validates Application.cfc settings:
- `this.name` - Application name
- `this.sessionManagement` - Session handling
- Route definitions not empty

### Database Configuration
Looks for database setup in:
- `config/settings.cfm` - datasource settings
- `.env` - Database environment variables
- Checks for existing migrations

### Permissions
Tests write permissions on:
- `db/migrate/` - For migrations
- `public/files/` - For uploads
- `tmp/` - For temporary files
- `logs/` - For log files

### Dependencies
Verifies package management:
- CFWheels listed in dependencies
- Modules directory exists
- Dependencies installed

### Environment
Checks runtime environment:
- CFML engine version
- Test suite presence
- Security files (.gitignore)

## Health Status Levels

### HEALTHY
All checks passed:
```
Health Status: HEALTHY
All 23 checks passed!
```

### WARNING
Non-critical issues found:
```
Health Status: WARNING
Found 3 warnings that should be addressed.
```

### CRITICAL
Must-fix issues found:
```
Health Status: CRITICAL
Found 2 critical issues that need immediate attention.
```

## Common Issues and Solutions

### Missing Directories
```
✗ Missing critical directory: app/helpers
```
**Solution**: Run `wheels g app` or create manually

### Database Not Configured
```
✗ Database configuration not found
```
**Solution**: Add datasource to `config/settings.cfm`:
```cfml
set(dataSourceName="myapp");
```

### No Write Permissions
```
⚠ No write permission: logs
```
**Solution**: Fix permissions:
```bash
chmod 755 logs
```

### Dependencies Not Installed
```
⚠ Modules not installed (run 'box install')
```
**Solution**: Install dependencies:
```bash
box install
```

### No Tests
```
⚠ No tests found
```
**Solution**: Create test structure:
```bash
wheels g test User
```

## Use Cases

### 1. New Project Setup
After creating a project:
```bash
wheels g app myapp
cd myapp
wheels doctor
```

### 2. Pre-Deployment Check
Before deploying:
```bash
wheels doctor
# Fix any critical issues
# Deploy only when "HEALTHY" or minor "WARNING"
```

### 3. Environment Verification
After server setup:
```bash
wheels doctor verbose=true
# Verify all components are properly configured
```

### 4. Troubleshooting
When things aren't working:
```bash
wheels doctor verbose=true > health-report.txt
# Share report when seeking help
```

### 5. CI/CD Integration
In build pipeline:
```bash
# Fail build on critical issues
wheels doctor || exit 1
```

## Recommendations

The doctor provides specific recommendations:

### Database Issues
- Configure database connection
- Create database with `wheels db create`
- Run migrations with `wheels dbmigrate latest`

### Missing Directories
- Use generators to create structure
- Ensure proper Wheels conventions

### Testing
- Add test files to `/tests`
- Use `wheels g test` to create tests

### Security
- Add `.gitignore` for sensitive files
- Check file permissions

## Best Practices

1. **Run Regularly**: Include in development workflow
2. **Fix Critical Issues First**: Address red ✗ items immediately
3. **Address Warnings**: Yellow ⚠ items before production
4. **Automate Checks**: Add to CI/CD pipeline
5. **Document Exceptions**: If ignoring warnings, document why

## Integration

### Git Hooks
```bash
# pre-commit hook
#!/bin/bash
wheels doctor || {
  echo "Health check failed. Fix issues before committing."
  exit 1
}
```

### CI/CD
```yaml
# .github/workflows/health.yml
- name: Health Check
  run: |
    box install
    wheels doctor
```

## Related Commands

- [`wheels about`](about.md) - Application information
- [`wheels test`](../testing/test.md) - Run test suite
- [`wheels db status`](../database/db-status.md) - Database status
- [`wheels deps list`](../core/deps.md) - Check dependencies

## Tips

- Run after cloning a project
- Use verbose mode for complete picture
- Save output for documentation
- Create project-specific health standards
- Consider health status in deployment decisions

## Customization

Future versions may support:
- Custom health check plugins
- Project-specific checks via `.doctor.json`
- Severity level configuration
- Integration with monitoring tools