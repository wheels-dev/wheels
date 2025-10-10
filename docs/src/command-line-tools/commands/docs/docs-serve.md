# wheels docs serve

Serves generated documentation locally for development and review.

## Usage

```bash
wheels docs serve [--root=<dir>] [--port=<port>] [--open]
```
## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--root` | Root directory to serve | `docs/api` |
| `--port` | Port to serve on | `35729` |
| `--open` | Open browser automatically | `true` |

## Description

The `docs serve` command starts a local web server to preview your generated documentation.


## Examples

### Basic documentation server
```bash
wheels docs serve
```

### Serve on different port
```bash
wheels docs serve --port=8080
```

### Serve from custom directory
```bash
wheels docs serve --root=public/api-docs
```

### Serve without opening browser
```bash
wheels docs serve --open=false
```

### Custom configuration
```bash
wheels docs serve --root=docs/generated --port=3000
```

## Server Output

```
Output directory: D:\Command Box\wheels\templates\base\src\docs\api\
CommandBox:src> wheels docs serve
 √ | Starting Server
   | √ | Setting site [wheels-docs-BBAA12EF-7A83-4D03-BD6DBFE4AC17C1F9] Profile to [development]
   | √ | Loading CFConfig into server

Status: starting
Server is still starting... waiting...
Server is up and running!
Starting documentation server...

Documentation server started!

Serving: D:\Command Box\wheels\templates\base\src\docs\api\
URL: http://localhost:35729
Opening browser...

Press Ctrl+C to stop the server
```

If documentation is not found:
```
Documentation directory not found: /docs/api

💡 Tip: Run 'wheels docs generate' first to create documentation
```

## Features

### Browser Integration
With `--open=true` (default), the server automatically opens your default browser to the documentation URL.

## Development Workflow

### Typical usage:
```bash
# Step 1: Generate documentation
wheels docs generate

# Step 2: Serve documentation
wheels docs serve

# Step 3: Make changes and regenerate
wheels docs generate
# Browser will show updated docs
```

### Custom workflow:
```bash
# Generate and serve from custom location
wheels docs generate --output=public/docs
wheels docs serve --root=public/docs --port=8080
```

## Troubleshooting

### Port already in use
```bash
# Use a different port
wheels docs serve --port=8081
```

### Documentation not found
```bash
# Make sure to generate docs first
wheels docs generate
wheels docs serve
```

### Browser doesn't open
```bash
# Manually navigate to the URL shown
# Or check your default browser settings
```

## Notes

- Server is intended for development/review only
- For production, deploy static files to web server
- Large documentation sets may take time to generate
- Offline mode caches documentation locally