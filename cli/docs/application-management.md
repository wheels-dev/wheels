# Application Management Commands

The Wheels CLI provides several commands for managing your application's lifecycle.

## Init

Creates a new Wheels application.

### Usage

```bash
wheels init [name] [path] [reload] [version] [createFolders]
```

### Parameters

- `name`: Name of the application (default: cfwheels)
- `path`: Path for the new application (default: current directory)
- `reload`: Force a reload of the application (default: false)
- `version`: Wheels version to use (default: latest)
- `createFolders`: Create standard folders structure (default: true)

### Examples

```bash
# Create a new application in the current directory
wheels init myApp

# Create a new application with a specific version
wheels init myApp version=2.2.0

# Create a new application in a specific directory
wheels init myApp path=/path/to/apps
```

## Reload

Reloads the Wheels application, which is useful during development after making changes to the codebase.

### Usage

```bash
wheels reload
```

### Examples

```bash
# Reload the application
wheels reload
```

## Info

Displays information about the Wheels application, including the version, environment, database configuration, and plugins.

### Usage

```bash
wheels info
```

### Examples

```bash
# Display application information
wheels info
```

## Watch

Monitors file changes in the application and automatically reloads the application during development.

### Usage

```bash
wheels watch [--includeDirs=controllers,models,views,config] [--excludeFiles=*.txt,*.log] [--interval=1]
```

### Parameters

- `includeDirs`: Comma-delimited list of directories to watch (default: controllers,models,views,config)
- `excludeFiles`: Comma-delimited list of file patterns to ignore (default: none)
- `interval`: Interval in seconds to check for changes (default: 1)

### Examples

```bash
# Watch with default settings
wheels watch

# Watch specific directories
wheels watch --includeDirs=controllers,models

# Exclude specific file types and set a different check interval
wheels watch --excludeFiles=*.txt,*.log,*.tmp --interval=2
```

### Notes

- The watch command keeps running until you press Ctrl+C to stop it
- When a file change is detected, it automatically triggers a reload of your application
- This is particularly useful during development to avoid manually reloading after each change
- You can customize which directories are monitored and which file types are ignored
- The interval parameter controls how frequently the system checks for changes (in seconds)