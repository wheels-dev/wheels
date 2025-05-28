# docs serve

Serves generated documentation locally with live reload for development and review.

## Usage

```bash
wheels docs serve [--port=<port>] [--host=<host>] [--open] [--watch]
```

## Parameters

- `--port` - (Optional) Port number to serve on. Default: `4000`
- `--host` - (Optional) Host to bind to. Default: `localhost`
- `--open` - (Optional) Open browser automatically after starting
- `--watch` - (Optional) Watch for changes and regenerate. Default: true

## Description

The `docs serve` command starts a local web server to preview your generated documentation. It includes:

- Live reload on documentation changes
- Search functionality
- Responsive design preview
- Print-friendly styling
- Offline access support

## Examples

### Basic documentation server
```bash
wheels docs serve
```

### Serve on different port
```bash
wheels docs serve --port=8080
```

### Open in browser automatically
```bash
wheels docs serve --open
```

### Serve without watching for changes
```bash
wheels docs serve --no-watch
```

### Bind to all interfaces
```bash
wheels docs serve --host=0.0.0.0
```

## Server Output

```
Starting documentation server...
================================

Configuration:
- Documentation path: /docs/generated/
- Server URL: http://localhost:4000
- Live reload: enabled
- File watching: enabled

Server started successfully!
- Local: http://localhost:4000
- Network: http://192.168.1.100:4000

Press Ctrl+C to stop the server

[2024-01-15 14:30:22] Serving documentation...
[2024-01-15 14:30:45] GET / - 200 OK (15ms)
[2024-01-15 14:30:46] GET /models/user.html - 200 OK (8ms)
[2024-01-15 14:31:02] File changed: /app/models/User.cfc
[2024-01-15 14:31:02] Regenerating documentation...
[2024-01-15 14:31:05] Documentation updated - reloading browsers
```

## Features

### Live Reload
When `--watch` is enabled, the server:
- Monitors source files for changes
- Automatically regenerates affected documentation
- Refreshes browser without manual reload

### Search Functionality
- Full-text search across all documentation
- Instant results as you type
- Keyboard navigation (Ctrl+K or Cmd+K)
- Search history

### Navigation
```
Documentation Structure:
/                     # Home page with overview
/models/              # All models documentation
/models/user.html     # Specific model docs
/controllers/         # Controller documentation  
/api/                 # API reference
/guides/              # Custom guides
/search               # Search page
```

### Print Support
- Optimized CSS for printing
- Clean layout without navigation
- Page breaks at logical points
- Print entire docs or single pages

## Development Workflow

### Typical usage during development:
```bash
# Terminal 1: Start the docs server
wheels docs serve --open

# Terminal 2: Make code changes
# Edit your models/controllers
# Documentation auto-updates

# Terminal 3: Generate fresh docs if needed
wheels docs generate
```

### Review workflow:
```bash
# Generate and serve for team review
wheels docs generate --format=html
wheels docs serve --port=3000 --host=0.0.0.0

# Share URL with team
echo "Documentation available at http://$(hostname -I | awk '{print $1}'):3000"
```

## Configuration

### Server Configuration
Create `/config/docs-server.json`:
```json
{
  "server": {
    "port": 4000,
    "host": "localhost",
    "baseUrl": "/docs",
    "cors": true
  },
  "watch": {
    "enabled": true,
    "paths": ["app/", "config/"],
    "ignore": ["*.log", "temp/"],
    "delay": 1000
  },
  "features": {
    "search": true,
    "print": true,
    "offline": true,
    "analytics": false
  }
}
```

### Custom Headers
```json
{
  "headers": {
    "Cache-Control": "no-cache",
    "X-Frame-Options": "SAMEORIGIN",
    "Content-Security-Policy": "default-src 'self'"
  }
}
```

## Access Control

### Basic Authentication
```bash
wheels docs serve --auth=username:password
```

### IP Restrictions
```bash
wheels docs serve --allow="192.168.1.0/24,10.0.0.0/8"
```

## Troubleshooting

### Common Issues

**Port already in use:**
```bash
Error: Port 4000 is already in use

# Solution: Use a different port
wheels docs serve --port=4001
```

**Cannot access from network:**
```bash
# Bind to all interfaces
wheels docs serve --host=0.0.0.0

# Check firewall settings
```

**Documentation not updating:**
```bash
# Force regeneration
wheels docs generate --force
wheels docs serve --watch
```

## Notes

- Server is intended for development/review only
- For production, deploy static files to web server
- Large documentation sets may take time to generate
- Browser must support JavaScript for search
- Offline mode caches documentation locally