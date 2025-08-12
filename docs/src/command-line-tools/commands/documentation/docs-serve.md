# docs serve (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Serves generated documentation locally for development and review.

## Usage

```bash
wheels docs serve [--root=<dir>] [--port=<port>] [--open] [--watch]
```

## Parameters

- `--root` - (Optional) Root directory to serve. Default: `docs/api`
- `--port` - (Optional) Port to serve on. Default: `35729`
- `--open` - (Optional) Open browser automatically. Default: `true`
- `--watch` - (Optional) Watch for changes and regenerate. Default: `false`

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

### Serve from custom directory
```bash
wheels docs serve --root=public/api-docs
```

### Serve with file watching
```bash
wheels docs serve --watch
```

### Serve without opening browser
```bash
wheels docs serve --open=false
```

### Custom configuration
```bash
wheels docs serve --root=docs/generated --port=3000 --watch
```

## Server Output

```
🌐 Starting documentation server...

Server started successfully!
- URL: http://localhost:35729
- Root: /docs/api
- Auto-open: enabled

Press Ctrl+C to stop the server
```

If documentation is not found:
```
Documentation directory not found: /docs/api

💡 Tip: Run 'wheels docs generate' first to create documentation
```

## Features

### File Watching
When `--watch` is enabled, the server monitors documentation files for changes and can trigger regeneration.

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
- Browser must support JavaScript for search
- Offline mode caches documentation locally