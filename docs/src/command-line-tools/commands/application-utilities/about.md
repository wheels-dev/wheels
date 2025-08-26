# wheels about

Display comprehensive information about your Wheels application and environment.

## Synopsis

```bash
wheels about
```

## Description

The `about` command provides a complete overview of your Wheels application, including framework versions, environment details, configuration status, and application statistics. It's your go-to command for understanding the current state of your application.

## Options

This command has no options.

## Examples

### Basic Usage

```bash
wheels about
```

Output:
```
  _____ _______          ___               _     
 / ____|  ____\ \        / / |             | |    
| |    | |__   \ \  /\  / /| |__   ___  ___| |___ 
| |    |  __|   \ \/  \/ / | '_ \ / _ \/ _ \ / __|
| |____| |       \  /\  /  | | | |  __/  __/ \__ \
 \_____|_|        \/  \/   |_| |_|\___|\___|_|___/

Wheels Framework
  Version: 2.5.0

Wheels CLI
  Version: 1.0.0
  Location: /commandbox/modules/wheels-cli/

Application
  Path: /Users/developer/myapp
  Name: MyWheelsApp
  Environment: development
  Database: Configured

Server Environment
  CFML Engine: Lucee 5.4.1.8
  Java Version: 11.0.15
  OS: macOS 13.0
  Architecture: x86_64

CommandBox
  Version: 5.9.0
  Home: /Users/developer/.CommandBox

Application Statistics
  Controllers: 12
  Models: 8
  Views: 45
  Tests: 23
  Migrations: 15

Resources
  Documentation: https://wheels.dev/guides
  API Reference: https://wheels.dev/api/v3.0.0
  GitHub: https://github.com/wheels-dev/wheels
  Community: https://wheels.dev/community
```

## Information Sections

### Wheels Framework
- **Version**: The version of Wheels framework installed
- Shows the core framework version your app is using

### Wheels CLI
- **Version**: Version of the Wheels CLI module
- **Location**: Where the CLI module is installed

### Application
- **Path**: Current application directory
- **Name**: Application name from Application.cfc
- **Environment**: Current environment (development/testing/production)
- **Database**: Whether database is configured

### Server Environment
- **CFML Engine**: Lucee or Adobe ColdFusion with version
- **Java Version**: JVM version being used
- **OS**: Operating system name and version
- **Architecture**: System architecture (x86_64, arm64, etc.)

### CommandBox
- **Version**: CommandBox version
- **Home**: CommandBox home directory

### Application Statistics
- **Controllers**: Number of controller CFCs
- **Models**: Number of model CFCs
- **Views**: Number of view templates
- **Tests**: Number of test files
- **Migrations**: Number of database migrations

### Resources
Quick links to:
- Official documentation
- API reference
- GitHub repository
- Community forums

## Use Cases

### 1. Environment Verification
Before deployment or when debugging:
```bash
wheels about
```
Check that:
- Correct Wheels version is installed
- Environment is set properly
- Database is configured

### 2. New Team Member Onboarding
Help new developers understand:
- Application structure (controllers, models, views count)
- Development environment setup
- Where to find documentation

### 3. Troubleshooting
When reporting issues:
```bash
wheels about > environment-info.txt
```
Share the output to provide complete context.

### 4. Project Documentation
Include output in project README to document:
- Required Wheels version
- CFML engine requirements
- Application structure overview

## Environment Detection

The command detects the environment through:
1. `server.json` WHEELS_ENV setting
2. System environment variable WHEELS_ENV
3. Default to "development" if not set

## Database Configuration

Database status is determined by checking:
1. `config/settings.cfm` for datasource settings
2. `.env` file for database environment variables
3. Presence of database-related configuration

## Statistics Collection

Statistics are gathered by counting files in:
- `/app/controllers/*.cfc` - Controllers
- `/app/models/*.cfc` - Models
- `/app/views/**/*.cfm` - Views
- `/tests/**/*.cfc` - Tests
- `/db/migrate/*.cfc` - Migrations

## Related Commands

- [`wheels version`](../core/info.md#version) - Show just version information
- [`wheels doctor`](doctor.md) - Run health checks
- [`wheels stats`](stats.md) - Detailed code statistics
- [`wheels env`](../environment/env.md) - Manage environments

## Tips

- Run `wheels about` when starting work on an unfamiliar project
- Include output in bug reports for better troubleshooting
- Use to verify environment after deployment
- Check before upgrading Wheels or CFML engine

## Customization

The application name is read from:
```cfml
// Application.cfc
this.name = "MyWheelsApp";
```

Environment can be set via:
```json
// server.json
{
  "env": {
    "WHEELS_ENV": "production"
  }
}
```

## Troubleshooting

### Missing Information

If some information is missing:
- **Application Name**: Check Application.cfc has `this.name` set
- **Database Status**: Ensure database configuration exists
- **Statistics**: Verify directory structure follows Wheels conventions

### Permission Issues

If statistics can't be calculated:
- Check read permissions on application directories
- Ensure you're running from application root