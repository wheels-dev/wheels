# Maintenance Mode Commands

## Overview

The maintenance mode commands allow you to control application availability during deployments, upgrades, or maintenance tasks. When maintenance mode is enabled, users see a maintenance message instead of the regular application, with options for IP whitelisting and custom redirects.

## Commands

### wheels maintenance:on

Enable maintenance mode for your application.

```bash
wheels maintenance:on [message] [allowedIPs] [redirectURL] [--force]
```

#### Parameters

- `message` - Custom maintenance message to display (default: "The application is currently undergoing maintenance. Please check back soon.")
- `allowedIPs` - Comma-separated list of IP addresses that can bypass maintenance mode
- `redirectURL` - Optional URL to redirect users to during maintenance
- `--force` - Skip confirmation prompt

#### Examples

```bash
# Basic maintenance mode
wheels maintenance:on

# Custom message
wheels maintenance:on message="We'll be back at 3:00 PM EST"

# Allow admin IPs to bypass
wheels maintenance:on allowedIPs="192.168.1.100,10.0.0.5"

# Redirect to status page
wheels maintenance:on redirectURL="https://status.example.com"

# Combined options without confirmation
wheels maintenance:on \
  message="Scheduled maintenance in progress" \
  allowedIPs="192.168.1.100" \
  redirectURL="/status" \
  --force
```

#### How It Works

1. Creates a `.maintenance` file in the `config/` directory containing:
   - Enabled status
   - Custom message
   - Allowed IP addresses
   - Redirect URL
   - Timestamp when enabled
   - Username who enabled it

2. Automatically updates `Application.cfc` to add a maintenance check:
   - Adds `checkMaintenanceMode()` private method
   - Calls it from `onRequestStart()`
   - Backs up original Application.cfc

3. When a request is made:
   - Checks if maintenance mode is enabled
   - Allows whitelisted IPs through
   - Redirects to custom URL if specified
   - Otherwise shows maintenance page with message

### wheels maintenance:off

Disable maintenance mode and restore normal application access.

```bash
wheels maintenance:off [--force] [--cleanup]
```

#### Parameters

- `--force` - Skip confirmation prompt
- `--cleanup` - Remove maintenance check from Application.cfc

#### Examples

```bash
# Basic disable
wheels maintenance:off

# Skip confirmation
wheels maintenance:off --force

# Clean up Application.cfc modifications
wheels maintenance:off --cleanup
```

#### What It Shows

- Current maintenance configuration
- How long maintenance mode was active
- Who enabled maintenance mode

## Best Practices

### 1. Deployment Workflow

```bash
# Enable maintenance before deployment
wheels maintenance:on message="Upgrading to version 2.0" --force

# Pull latest code
git pull origin main

# Run database migrations
wheels dbmigrate latest

# Clear caches
wheels cache:clear

# Run tests
wheels test app

# Disable maintenance
wheels maintenance:off --force
```

### 2. Scheduled Maintenance

```bash
# Schedule maintenance with clear messaging
wheels maintenance:on \
  message="Scheduled maintenance: 2:00 AM - 4:00 AM EST. We apologize for any inconvenience." \
  redirectURL="/maintenance-schedule"
```

### 3. Emergency Maintenance

```bash
# Quick emergency maintenance
wheels maintenance:on message="Emergency maintenance in progress" --force

# Allow only admin access
wheels maintenance:on \
  message="System maintenance" \
  allowedIPs="192.168.1.100" \
  --force
```

### 4. Testing Maintenance Mode

```bash
# Enable with your IP allowed
wheels maintenance:on allowedIPs="$(curl -s ifconfig.me)"

# Test from another IP or incognito window
# Should see maintenance page

# Disable when done
wheels maintenance:off
```

## Configuration Storage

The maintenance configuration is stored in `config/.maintenance` as JSON:

```json
{
  "enabled": true,
  "message": "The application is currently undergoing maintenance...",
  "allowedIPs": "192.168.1.100,10.0.0.5",
  "redirectURL": "",
  "enabledAt": "2024-01-15 14:30:00",
  "enabledBy": "admin"
}
```

## Application.cfc Integration

The maintenance check is automatically added to your Application.cfc:

```cfml
private function checkMaintenanceMode() {
    var maintenanceFile = expandPath("/config/.maintenance");
    if (fileExists(maintenanceFile)) {
        var config = deserializeJSON(fileRead(maintenanceFile));
        if (config.enabled) {
            // Check if current IP is allowed
            var clientIP = cgi.remote_addr;
            if (len(config.allowedIPs) && listFindNoCase(config.allowedIPs, clientIP)) {
                return; // Allow access
            }
            
            // Handle redirect
            if (len(config.redirectURL)) {
                location(url=config.redirectURL, addtoken=false);
            }
            
            // Show maintenance message
            writeOutput("<!DOCTYPE html>...");
            abort;
        }
    }
}
```

## Troubleshooting

### Maintenance Mode Not Working

1. Check if `.maintenance` file exists in `config/` directory
2. Verify Application.cfc has the maintenance check
3. Ensure file permissions allow reading the maintenance file
4. Check server logs for errors

### Can't Disable Maintenance Mode

1. Use `--force` flag to skip confirmation
2. Manually delete `config/.maintenance` file if needed
3. Use `--cleanup` to remove Application.cfc modifications

### IP Whitelisting Not Working

1. Check the actual client IP: `cgi.remote_addr`
2. Behind a proxy? May need to check `cgi.http_x_forwarded_for`
3. Verify IP format in allowedIPs parameter

## Related Commands

- [wheels cache:clear](../assets-cache-management.md) - Clear caches after maintenance
- [wheels dbmigrate latest](../database/dbmigrate-latest.md) - Run migrations during maintenance
- [wheels reload](../core/reload.md) - Reload application after changes