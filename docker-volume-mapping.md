# Docker Volume Mappings for lucee6 Container

## Volume Mappings (Updated Structure)

### 1. Template Base Source
**Host:** `./templates/base/src`  
**Container:** `/cfwheels-test-suite`

This is the main application directory containing:
- `/app` - Application code (controllers, models, views)
- `/config` - Configuration files
- `/public` - Web root with index.cfm and urlrewrite.xml
- `/vendor` - Dependencies (populated by box install)
- `Application.cfc` - Main application file
- `box.json` - Package dependencies

### 2. Wheels Core Framework
**Host:** `./core/src/wheels`  
**Container:** `/cfwheels-test-suite/vendor/wheels`

This maps the core Wheels framework into the vendor directory.

### 3. Server Configuration
**Host:** `./tools/docker/lucee@6/server.json`  
**Container:** `/cfwheels-test-suite/server.json`

This overrides the server.json with Lucee 6 specific configuration.

### 4. Application Settings
**Host:** `./tools/docker/lucee@6/settings.cfm`  
**Container:** `/cfwheels-test-suite/config/settings.cfm`

This places the Lucee 6 specific settings.cfm in the config directory.

### 5. Package Dependencies
**Host:** `./templates/base/src/box.json`  
**Container:** `/cfwheels-test-suite/box.json`

This ensures the box.json is available for dependency management.

### 6. CF Engine Configuration
**Host:** `./tools/docker/lucee@6/CFConfig.json`  
**Container:** `/cfwheels-test-suite/CFConfig.json`

This provides the ColdFusion engine configuration for Lucee 6.

## Dependencies Installed via box.json

During the Docker build process, `box install` is run which installs:
- **wirebox** (v7.x) - Dependency injection framework
- **testbox** (v5.x) - Testing framework

These are installed into `/cfwheels-test-suite/vendor/` directory.

## Container Working Directory

The CommandBox server starts from `/cfwheels-test-suite` and uses:
- **Web root:** `/cfwheels-test-suite/public` (as defined in server.json)
- **Config:** `/cfwheels-test-suite/CFConfig.json` (for CF engine settings)
- **Server Home:** `/cfwheels-test-suite/.engine/lucee@6`

## Accessing the Application

The server is configured to serve files from the `public` directory:
- `http://localhost:60006/` → Wheels welcome page
- Application is fully functional with all dependencies installed