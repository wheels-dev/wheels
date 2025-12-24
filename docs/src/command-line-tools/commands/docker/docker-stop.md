# Wheels Docker Stop Command Guide

## Overview

The `wheels docker stop` command provides a unified interface to stop Docker containers for your Wheels application on both local machines and remote servers. It intelligently detects whether you're using Docker Compose or standard Docker commands and handles container shutdown accordingly.

---

## Command Syntax

```bash
wheels docker stop [mode] [options]
```

### Modes

- `--local` - Stop containers on local machine (default if no mode specified)
- `--remote` - Stop containers on remote server(s)

---

## Parameters Reference

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `local` | Boolean | No | true* | Stop containers on local machine |
| `remote` | Boolean | No | false | Stop containers on remote server(s) |
| `servers` | String | No | "" | Comma-separated list of server numbers to stop (e.g., "1,3,5") - for remote only |
| `removeContainer` | Boolean | No | false | Also remove the container after stopping |

**Note:** If neither `--local` nor `--remote` is specified, `--local` is used by default.

---

## Usage Examples

### Local Operations

#### Basic Local Stop (Default)

Stop containers on your local machine:

```bash
wheels docker stop
```

or explicitly:

```bash
wheels docker stop --local
```

#### Stop and Remove Local Container

Stop the container and also remove it:

```bash
wheels docker stop --local --removeContainer
```

#### Stop Local Docker Compose Services

If you have a `docker-compose.yml` or `docker-compose.yaml` file, it will automatically use Docker Compose:

```bash
wheels docker stop --local
```

**Output:**
```
Found docker-compose file, will stop docker-compose services
Stopping services with docker-compose...
Docker Compose services stopped successfully!
```

---

### Remote Operations

#### Stop All Remote Servers

Stop containers on all servers defined in your configuration file:

```bash
wheels docker stop --remote
```

#### Stop Specific Remote Servers

Stop containers only on specific servers (by their position in the config file):

```bash
wheels docker stop --remote --servers=1,3,5
```

This stops containers on the 1st, 3rd, and 5th servers in your configuration.

#### Stop and Remove on Remote Servers

Stop and remove containers on all remote servers:

```bash
wheels docker stop --remote --removeContainer
```

#### Stop Specific Servers and Remove

Combine server selection with container removal:

```bash
wheels docker stop --remote --servers=2,4 --removeContainer
```

---

## Advanced Usage Examples

### Development Workflow

#### Clean Restart Local Environment

Stop and remove local containers for a clean restart:

```bash
wheels docker stop --local --removeContainer
```

Then start fresh:
```bash
wheels docker deploy local
```

#### Stop Staging Servers

If servers 1-3 are staging in your config:

```bash
wheels docker stop --remote --servers=1,2,3
```

#### Stop Production Servers

If servers 4-6 are production:

```bash
wheels docker stop --remote --servers=4,5,6
```

### Maintenance Scenarios

#### Rolling Restart - Stop Half

Stop half of your servers for maintenance:

```bash
# Stop servers 1, 3, 5 (odd-numbered)
wheels docker stop --remote --servers=1,3,5
```

Perform maintenance, then restart:
```bash
wheels docker deploy remote --servers=deploy-servers.json
```

Then stop the other half:
```bash
# Stop servers 2, 4, 6 (even-numbered)
wheels docker stop --remote --servers=2,4,6
```

#### Emergency Stop All

Quickly stop all remote containers:

```bash
wheels docker stop --remote
```

#### Complete Cleanup

Stop and remove all containers on all servers:

```bash
wheels docker stop --remote --removeContainer
```

---

## Server Configuration

The `wheels docker stop` command uses the same server configuration files as other Docker commands.

### Configuration File Locations

The command automatically looks for these files in your project root:

1. `deploy-servers.txt` (simple text format)
2. `deploy-servers.json` (detailed JSON format)

### deploy-servers.txt Format

Simple format with space or tab-separated values:

```text
192.168.1.100 ubuntu 22
production.example.com deploy 22
staging.example.com deploy 2222
```

**Format:** `host user [port]`
- `host` - Server hostname or IP address (required)
- `user` - SSH username (required)
- `port` - SSH port (optional, default: 22)

**Example with comments:**
```text
## Production Servers
web1.example.com deploy 22
web2.example.com deploy 22

## Staging Servers
staging1.example.com deploy 22
staging2.example.com deploy 22
```

### deploy-servers.json Format

Detailed format with full configuration options:

```json
{
  "servers": [
    {
      "host": "web1.example.com",
      "user": "deploy",
      "port": 22,
      "imageName": "myapp",
      "remoteDir": "/home/deploy/myapp"
    },
    {
      "host": "web2.example.com",
      "user": "deploy",
      "port": 2222,
      "imageName": "myapp",
      "remoteDir": "/opt/applications/myapp"
    },
    {
      "host": "staging.example.com",
      "user": "ubuntu",
      "port": 22,
      "imageName": "myapp-staging",
      "remoteDir": "/home/ubuntu/myapp-staging"
    }
  ]
}
```

**JSON Parameters:**
- `host` - Server hostname or IP address (required)
- `user` - SSH username (required)
- `port` - SSH port (optional, default: 22)
- `imageName` - Docker container/image name (optional, default: project name)
- `remoteDir` - Remote application directory (optional, default: `/home/[user]/[project-name]`)

---

## Server Selection

### Selecting Specific Servers

When using the `--servers` parameter, you specify servers by their position (1-indexed) in the configuration file:

**Example Configuration:**
```text
# Server 1
web1.example.com deploy 22
# Server 2
web2.example.com deploy 22
# Server 3
web3.example.com deploy 22
# Server 4
db.example.com deploy 22
```

**Stop only servers 1 and 3:**
```bash
wheels docker stop --remote --servers=1,3
```

**Stop servers 2, 3, and 4:**
```bash
wheels docker stop --remote --servers=2,3,4
```

### Invalid Server Numbers

If you specify invalid server numbers, they will be skipped:

```bash
wheels docker stop --remote --servers=1,99,3
```

**Output:**
```
Skipping invalid server number: 99
Selected 2 of 4 server(s)
```

If no valid servers are selected, all servers will be used:
```bash
wheels docker stop --remote --servers=99,100
```

**Output:**
```
Skipping invalid server number: 99
Skipping invalid server number: 100
No valid servers selected, using all servers
```

---

## Docker Compose vs Standard Docker

The stop command intelligently detects which approach to use:

### Docker Compose Mode

**Detection:** Looks for `docker-compose.yml` or `docker-compose.yaml` in:
- Local: Your current project directory
- Remote: The `remoteDir` on the server

**Command Used:**
```bash
docker compose down
```

**Benefits:**
- Stops all services defined in the compose file
- Removes networks created by compose
- Cleaner multi-container shutdown

### Standard Docker Mode

**Used When:** No Docker Compose file is found

**Command Used:**
```bash
docker stop [container-name]
```

**Optional Container Removal:**
```bash
docker rm [container-name]
```

---

## Container Naming

The command uses your project name to identify containers:

### Project Name Derivation

Project name is derived from your current directory:
- Converted to lowercase
- Non-alphanumeric characters replaced with hyphens
- Multiple consecutive hyphens reduced to single hyphen
- Leading/trailing hyphens removed

**Examples:**
- Directory: `MyWheelsApp` → Container: `mywheelsapp`
- Directory: `wheels-blog-v2` → Container: `wheels-blog-v2`
- Directory: `My App 2024` → Container: `my-app-2024`

### Custom Container Names

You can specify custom container names in `deploy-servers.json`:

```json
{
  "servers": [
    {
      "host": "web1.example.com",
      "user": "deploy",
      "imageName": "custom-app-name"
    }
  ]
}
```

---

## Sudo Handling on Remote Servers

The command intelligently determines whether to use `sudo` for Docker commands:

### Check Performed

```bash
if groups | grep -q docker && [ -w /var/run/docker.sock ]; then
  docker stop [container]
else
  sudo docker stop [container]
fi
```

### Requirements for No-Sudo Operation

1. User is in the `docker` group
2. User has write access to `/var/run/docker.sock`

### Adding User to Docker Group

On the remote server:
```bash
sudo usermod -aG docker deploy
# Log out and back in for changes to take effect
```

---

## Error Handling and Recovery

### Container Not Running

If a container is not running, the command will display a warning but not fail:

```bash
wheels docker stop --local
```

**Output:**
```
Stopping Docker container 'myapp'...
Container might not be running: No such container
```

This is normal behavior and allows the command to complete successfully.

### SSH Connection Failures

**Error:** "SSH connection failed to web1.example.com. Check credentials and access."

**Solutions:**
1. Verify SSH connectivity:
   ```bash
   ssh user@host
   ```

2. Check SSH key authentication:
   ```bash
   ssh-add -l
   ```

3. Test with verbose output:
   ```bash
   ssh -v user@host
   ```

4. Verify port in configuration (default: 22)

### No Configuration File

**Error:** "No server configuration found. Create deploy-servers.txt or deploy-servers.json in your project root."

**Solution:** Create one of the configuration files:

**Quick setup (deploy-servers.txt):**
```bash
echo "your-server.com deploy 22" > deploy-servers.txt
```

**Or JSON format:**
```bash
cat > deploy-servers.json << 'EOF'
{
  "servers": [
    {
      "host": "your-server.com",
      "user": "deploy",
      "port": 22
    }
  ]
}
EOF
```

### Docker Not Installed Locally

**Error:** "Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running."

**Solutions:**
1. Install Docker Desktop (macOS/Windows)
2. Install Docker Engine (Linux)
3. Start Docker service:
   ```bash
   # macOS/Windows: Start Docker Desktop
   # Linux:
   sudo systemctl start docker
   ```

4. Verify installation:
   ```bash
   docker --version
   ```

---

## Operation Summary

When stopping multiple servers, a summary is displayed:

```bash
wheels docker stop --remote --servers=1,2,3
```

**Output:**
```
Stopping containers on 3 server(s)...

---------------------------------------
Stopping container on server 1 of 3: web1.example.com
---------------------------------------
...
Container on web1.example.com stopped successfully

---------------------------------------
Stopping container on server 2 of 3: web2.example.com
---------------------------------------
...
Container on web2.example.com stopped successfully

---------------------------------------
Stopping container on server 3 of 3: web3.example.com
---------------------------------------
...
Container on web3.example.com stopped successfully

Stop Operations Summary:
   Successful: 3
```

If any servers fail:
```
Stop Operations Summary:
   Successful: 2
   Failed: 1
```

---

## Best Practices

### 1. Always Test Locally First

Before stopping remote servers:
```bash
# Test the stop command locally
wheels docker stop --local

# Verify it works as expected
docker ps -a
```

### 2. Use Server Selection for Staged Rollouts

Don't stop all servers at once in production:
```bash
# Stop first half
wheels docker stop --remote --servers=1,2

# Verify, then stop second half
wheels docker stop --remote --servers=3,4
```

### 3. Remove Containers During Maintenance

For major updates or troubleshooting:
```bash
wheels docker stop --remote --removeContainer
```

This ensures a completely clean slate for the next deployment.

### 4. Check Status After Stopping

Verify containers are stopped:
```bash
wheels docker stop --local
docker ps -a
```

### 5. Keep Configuration Files Secure

**Security recommendations:**
- Store configuration files outside version control (add to `.gitignore`)
- Use restrictive file permissions:
  ```bash
  chmod 600 deploy-servers.txt
  chmod 600 deploy-servers.json
  ```
- Use SSH keys instead of passwords
- Consider encrypting sensitive configuration

### 6. Document Server Numbers

Add comments to your configuration files:
```text
## Production Web Servers (1-3)
web1.example.com deploy 22
web2.example.com deploy 22
web3.example.com deploy 22

## Production Database (4)
db.example.com deploy 22

## Staging (5-6)
staging1.example.com deploy 22
staging2.example.com deploy 22
```

### 7. Use Descriptive Server Names

In JSON format, make server purposes clear:
```json
{
  "servers": [
    {
      "host": "prod-web-1.example.com",
      "user": "deploy",
      "imageName": "myapp-production"
    },
    {
      "host": "staging-web-1.example.com",
      "user": "deploy",
      "imageName": "myapp-staging"
    }
  ]
}
```

---

## Common Workflows

### Development Cycle

```bash
# 1. Stop local containers
wheels docker stop --local --removeContainer

# 2. Make code changes
# ... edit files ...

# 3. Rebuild and restart
wheels docker build local
wheels docker deploy local
```

### Deployment Update

```bash
# 1. Build new image
wheels docker build remote

# 2. Stop old containers (staged)
wheels docker stop --remote --servers=1,3,5

# 3. Deploy new version
wheels docker deploy remote --servers=1,3,5

# 4. Stop remaining servers
wheels docker stop --remote --servers=2,4,6

# 5. Deploy to remaining servers
wheels docker deploy remote --servers=2,4,6
```

### Emergency Rollback

```bash
# 1. Stop all production servers
wheels docker stop --remote --servers=1,2,3,4

# 2. Deploy previous version
wheels docker deploy remote --servers=production-servers.json

# 3. Verify deployment
wheels docker logs --remote --servers=1 tail=100
```

### Complete Cleanup

```bash
# Stop and remove everything
wheels docker stop --local --removeContainer
wheels docker stop --remote --removeContainer
```

---

## Integration with Other Commands

### Check Status Before Stopping

```bash
# Check which containers are running
wheels docker status

# Then stop specific ones
wheels docker stop --remote --servers=2,3
```

### View Logs Before Stopping

```bash
# Check for errors
wheels docker logs tail=100

# If issues found, stop and restart
wheels docker stop --local
wheels docker deploy local
```

### Complete Stop and Redeploy

```bash
# Stop with removal
wheels docker stop --remote --removeContainer

# Rebuild
wheels docker build remote

# Deploy fresh
wheels docker deploy remote
```

---

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker push](docker-push.md) - Push Docker images to registries
- [wheels docker login](docker-login.md) - Authenticate with registries
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker exec](docker-exec.md) - Execute commands in containers

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.

---

## Additional Notes

- Default mode is `--local` if neither `--local` nor `--remote` is specified
- Cannot specify both `--local` and `--remote` simultaneously
- SSH connections use key-based authentication (password auth not supported)
- Containers are stopped gracefully with default Docker stop timeout (10 seconds)
- Docker Compose down removes networks automatically
- The `--removeContainer` flag only removes the container, not the image
- Server selection is 1-indexed (starts at 1, not 0)
- Invalid server numbers are skipped with warnings
- The command attempts to detect sudo requirements automatically
- Exit status reflects overall operation success