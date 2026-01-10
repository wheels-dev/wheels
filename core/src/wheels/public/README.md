# Wheels GUI

Everything in `/wheels/public/` is aimed at the local developer. `/wheels/public/assets/` should be on the developers urlrewriting exemption for local CSS and JS already as it was introduced in wheels 2.x.

## Building

Rebuild the CSS by navigating to `wheels/public/assets/`

```
# Install gulp globally
npm install -g gulp

# Install dependencies
npm install

# Change dirs
cd semantic/

# Run Build
gulp build
```

## Functionality

#### /wheels/

Handles legacy `?controller=wheels&action=wheels&view=routes` style params

### /wheels/index
Initial congratulations screen

### /wheels/info
As much information as possible about the currently loaded environment, host and setup

### /wheels/routes
Route Listings - a quick searchable index. Also lists the internal routes used by this GUI. Adds an experimental route tester which can fire off a jquery request to the URL, or via CFHTTP, then explain why the request has matched the route it has, and also display what other routes it *could* have matched if the primary route hadn't been matched

### /wheels/route-tester
A POST endpoint for internal use in the above route tester

### /wheels/docs
All internal documentation - a merged collection of the core documentation and any other documentation that the developer sees fit to add to their app (assuming it matches the javaDoc style output of the internal functions)

### /wheels/packages
Displays all Core (if using master branch), App & Plugin Test packages. Includes a testrunner which can return multiple formats - html, json, junit

### /wheels/tests
The actual test runner

### /wheels/migrator
The database migration system

### /wheels/cli
Various endpoints for exclusive use by the CLI

### /wheels/plugins
All the Wheels plugins loaded and as much information as we have about them
