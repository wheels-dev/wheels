# v3 dev notes

## Breaking Changes:

 - Rocketunit is now marked as deprecated and will be removed in wheels 4
 - `Application.cfc`, `index.cfm`  will need to be replaced
 - `root.cfm` will need to be removed
 - TODO: `rewrite.cfm` will need to be replaced:  URL rewriting no longer uses `rewrite.cfm`, and will strictly determine URL behaviour from `set(urlRewriting="on")`
 - All includes within the core now use mappings with absolute links as opposed to relative links; whilst this shouldn't affect your application, it might affect plugins or other code which tries to use internal core methods.

## Testing:

 - Core tests now use testbox, and it's recommended to upgrade your own tests before moving to wheels 4

## App Structure:

 - This new version uses it's own `Application.cfc` which means you can set the mappings before wheels initializes; this means you can move the wheels folder outside the webroot and set any other folder mappings as you see fit.

 - There are two primary mappings:
  - `/wheels`     the mapping to the main wheels directory
  - `/app`        Application source code, i.e controllers, models, config etc.

 By Default:
 - `/app` points to the webroot
 - `/wheels` points to a subdirectory within the webroot named `wheels`

 This is so the developer has the easiest route to get going and won't require configuring mappings.

 You could for instance, set it up like:

 ```
 /app
  - /config
  - /controllers
  - /events
  - /global
  - /models
  - /migrator
  - /plugins
  - /views
/public <--- webroot
 - /images
 - /files
 - /javascripts
 - /stylesheets
 - Application.cfc <--- Bootstrapped
 - index.cfm
 - URLrewrite.xml
 - server.json
/vendor
 - /wheels
```

By using

```
this.webrootDir = getDirectoryFromPath( getCurrentTemplatePath() );
this.appDir     = getCanonicalPath(this.webrootDir & '../app');
this.wheelsDir  = getCanonicalPath(this.webrootDir & '../vendor/wheels');
this.mappings['/app']      = this.appDir;
this.mappings['/wheels']   = this.wheelsDir;
```

## Internal Stuff

 - $createObjectFromRoot() not longer requires `root.cfm` and simply $cfinvokes the component
 - $cfinvoke added a proxy to the tag equivalent

### Mapper / Routing
 - Where possible, internal methods are now private; exception is `$draw` which is called outside the CFC internally
 - Testbox uses `makePublic(mapper, "foo")` to allow these to be tested
 - Mapper now has a new method, `getRoutes()` which return the result of `variables.routes` (i.e the calculated routes)
 - Instead of directly assigning to `application.wheels.routes`, routes are returned via `getRoutes()` and assigned in `$loadRoutes`

### Running Core Tests

 - In commandbox, navigate to `wheels/` and do `install` to install testbox within the wheels folder;
 - Then go to `/wheels/tests` and do `server start`;
 - Then when the site opens go to `runner.cfm`;
 - The `/tests/` directory has it's own `Application.cfc` and mappings, with a "fake" app at `resources/app`