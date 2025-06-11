# CFWheels CLI Commands Testing Log

This document tracks the systematic testing of all CFWheels CLI commands. Each command will be tested with various parameters and the results will be documented here.

## Testing Status Legend
- ✅ Fully Tested - All parameters tested successfully
- ⚠️ Partially Tested - Some parameters tested, issues found
- ❌ Failed - Command fails to execute
- ⏳ Not Tested - Awaiting testing
- 🚫 Disabled - Command is disabled/broken

## Core Commands

### wheels init
- **Status**: ✅ Fully Tested
- **Parameters to test**:
  - Basic: `wheels init`
- **Test Results**:
  - **Basic init on new app**: ✅ Success
    - Creates box.json, server.json, and vendor/wheels/box.json
    - Prompts for: confirmation, version (if no box.json), app name, cfengine
    - Default cfengine: lucee@5
    - Files created with mode 777
  - **Init on app with existing files**: ✅ Success
    - Skips creation of existing files (box.json, server.json, wheels/box.json)
    - No prompts for app name/cfengine if server.json exists
  - **Partial existing files**: ✅ Success
    - Only creates missing files
    - Still prompts for required information for missing configs
  - **User declining (n)**: ✅ Success
    - Properly aborts with error message "Ok, aborting..."
  - **Note**: Command is interactive only - no parameters accepted
    - Does NOT automatically install dependencies (must run `box install` separately)

### wheels info
- **Status**: ✅ Fully Tested
- **Parameters to test**:
  - Basic: `wheels info`
- **Test Results**:
  - **Basic info in wheels app**: ✅ Success
    - Displays ASCII art header
    - Shows Current Working Directory
    - Shows CommandBox Module Root (/cfwheels-cli/)
    - Shows Current Wheels Version from vendor/wheels/box.json
  - **Info in non-wheels directory**: ✅ Success (with appropriate error)
    - Error: "We're currently looking in [path], but can't find the /vendor/wheels/ folder. Are you sure you are in the root?"
  - **Note**: Command accepts no parameters - output format is fixed

### wheels destroy
- **Status**: ✅ Fully Tested
- **Parameters to test**:
  - Resource: `wheels destroy Product`
  - Controller: `wheels destroy type=controller name=Products`
  - Model: `wheels destroy type=model name=Product`
  - View: `wheels destroy type=view name=products/index`
- **Test Results**:
  - **Basic destroy of existing resource**: ✅ Success
    - Shows confirmation prompt with list of files/directories to delete
    - Deletes model file (app/models/[Name].cfc)
    - Deletes controller file (app/controllers/[Names].cfc)
    - Deletes views directory (app/views/[names]/)
    - Removes route from routes.cfm
    - Creates database migration to drop table
    - Attempts to run migration (fails if server not running)
  - **Destroy with user declining (n)**: ✅ Success
    - Properly cancels without deleting anything
  - **Destroy non-existent resource**: ✅ Success
    - Shows what would be deleted (even if files don't exist)
    - Allows user to cancel
  - **Alias command `wheels d`**: ✅ Success
    - Works identically to `wheels destroy`
  - **Destroy individual controller**: ✅ Success
    - `wheels destroy type=controller name=User`
    - Deletes controller file and test file
    - Shows appropriate message if files don't exist
  - **Destroy individual model**: ✅ Success
    - `wheels destroy type=model name=User`
    - Deletes model file and test file
    - Creates migration to drop database table
  - **Destroy individual view**: ✅ Success
    - `wheels destroy type=view name=users/index` - deletes specific view
    - `wheels destroy type=view name=users` - deletes all views for controller
  - **Note**: Command now supports both full resource and individual component destruction
    - Default behavior (no type specified) destroys entire resource
    - Type parameter accepts: resource, controller, model, view
    - Test file deletion paths shown but test files not created by generate resource

### wheels deps
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - List: `wheels deps`
  - Install: `wheels deps --install`
  - Update: `wheels deps --update`
- **Test Results**:
  - _Pending_

### wheels reload
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Default: `wheels reload`
  - With environment: `wheels reload development`
  - With password: `wheels reload --password=mypass`
- **Test Results**:
  - _Pending_

### wheels watch
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels watch`
  - With path: `wheels watch path=app/models`
  - With extensions: `wheels watch extensions=cfc,cfm`
- **Test Results**:
  - _Pending_

## Code Generation Commands

### wheels generate app
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels generate app myapp`
  - With datasource: `wheels generate app myapp datasourceName=mydb`
  - With template: `wheels generate app myapp template=api`
  - With reload password: `wheels generate app myapp reloadPassword=secret`
- **Test Results**:
  - _Pending_

### wheels generate app-wizard
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Interactive: `wheels generate app-wizard`
- **Test Results**:
  - _Pending_

### wheels generate controller
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels generate controller Products`
  - With actions: `wheels generate controller Products actions=index,show,new,edit`
  - With format: `wheels generate controller Products format=json`
- **Test Results**:
  - _Pending_

### wheels generate model
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels generate model Product`
  - With properties: `wheels generate model Product properties=name:string,price:numeric`
  - With datasource: `wheels generate model Product datasource=mydb`
- **Test Results**:
  - _Pending_

### wheels generate view
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels generate view products/index`
  - With template: `wheels generate view products/show template=custom`
- **Test Results**:
  - _Pending_

### wheels generate property
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - String property: `wheels generate property Product name:string`
  - Numeric property: `wheels generate property Product price:numeric`
  - Boolean property: `wheels generate property Product active:boolean`
- **Test Results**:
  - _Pending_

### wheels generate resource
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels generate resource Product`
  - With properties: `wheels generate resource Product name:string,price:numeric`
  - Nested: `wheels generate resource Comment post:references`
- **Test Results**:
  - _Pending_

### wheels generate route
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Resource route: `wheels generate route resource:products`
  - Custom route: `wheels generate route get:/custom,controller:pages,action:custom`
- **Test Results**:
  - _Pending_

### wheels generate snippets
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - List: `wheels generate snippets`
  - Generate specific: `wheels generate snippets type=controller`
- **Test Results**:
  - _Pending_

### wheels generate test
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Model test: `wheels generate test model Product`
  - Controller test: `wheels generate test controller Products`
  - View test: `wheels generate test view products/index`
- **Test Results**:
  - _Pending_

### wheels generate api-resource
- **Status**: 🚫 Disabled
- **Test Results**:
  - Command is disabled (.broken/.disabled files exist)

### wheels generate frontend
- **Status**: 🚫 Disabled
- **Test Results**:
  - Command is disabled (.bak/.disabled files exist)

### wheels scaffold
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels scaffold Product name:string,price:numeric`
  - With namespace: `wheels scaffold admin/Product name:string`
- **Test Results**:
  - _Pending_

## Database Commands

### wheels db schema
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels db schema`
  - With format: `wheels db schema --format=json`
  - Specific table: `wheels db schema table=products`
- **Test Results**:
  - _Pending_

### wheels db seed
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels db seed`
  - With file: `wheels db seed file=testdata`
  - With environment: `wheels db seed environment=development`
- **Test Results**:
  - _Pending_

## Database Migration Commands

### wheels dbmigrate create blank
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels dbmigrate create blank AddCustomLogic`
  - With template: `wheels dbmigrate create blank MyMigration template=custom`
- **Test Results**:
  - _Pending_

### wheels dbmigrate create column
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Add column: `wheels dbmigrate create column products description:text`
  - With options: `wheels dbmigrate create column products active:boolean,default:true`
- **Test Results**:
  - _Pending_

### wheels dbmigrate create table
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels dbmigrate create table products name:string,price:numeric`
  - With timestamps: `wheels dbmigrate create table products name:string --timestamps`
- **Test Results**:
  - _Pending_

### wheels dbmigrate remove table
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels dbmigrate remove table products`
- **Test Results**:
  - _Pending_

### wheels dbmigrate up
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - All pending: `wheels dbmigrate up`
  - Specific version: `wheels dbmigrate up version=20240101120000`
  - Single step: `wheels dbmigrate up --step`
- **Test Results**:
  - _Pending_

### wheels dbmigrate down
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - One migration: `wheels dbmigrate down`
  - Specific version: `wheels dbmigrate down version=20240101120000`
  - Multiple steps: `wheels dbmigrate down steps=3`
- **Test Results**:
  - _Pending_

### wheels dbmigrate latest
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels dbmigrate latest`
  - Dry run: `wheels dbmigrate latest --dryRun`
- **Test Results**:
  - _Pending_

### wheels dbmigrate reset
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels dbmigrate reset`
  - With seed: `wheels dbmigrate reset --seed`
- **Test Results**:
  - _Pending_

### wheels dbmigrate info
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels dbmigrate info`
  - Verbose: `wheels dbmigrate info --verbose`
- **Test Results**:
  - _Pending_

### wheels dbmigrate exec
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Specific migration: `wheels dbmigrate exec version=20240101120000`
  - With direction: `wheels dbmigrate exec version=20240101120000 direction=down`
- **Test Results**:
  - _Pending_

## Configuration Commands

### wheels config env
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Show current: `wheels config env`
  - Set environment: `wheels config env set=production`
- **Test Results**:
  - _Pending_

### wheels config list
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - All settings: `wheels config list`
  - Specific category: `wheels config list category=database`
  - With format: `wheels config list --json`
- **Test Results**:
  - _Pending_

### wheels config set
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Single setting: `wheels config set dataSourceName=mydb`
  - Multiple settings: `wheels config set environment=production,cacheQueries=true`
- **Test Results**:
  - _Pending_

## Environment Commands

### wheels env
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Show current: `wheels env`
  - List all: `wheels env list`
- **Test Results**:
  - _Pending_

### wheels env list
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels env list`
  - With details: `wheels env list --detailed`
- **Test Results**:
  - _Pending_

### wheels env setup
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - New environment: `wheels env setup staging`
  - Copy from existing: `wheels env setup staging --copyFrom=development`
- **Test Results**:
  - _Pending_

### wheels env switch
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Switch to production: `wheels env switch production`
  - Switch with reload: `wheels env switch development --reload`
- **Test Results**:
  - _Pending_

## Testing Commands

### wheels test
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - All tests: `wheels test`
  - Specific bundle: `wheels test app testBundles=models`
  - Specific spec: `wheels test app testBundles=models&testSpecs=ProductTest`
- **Test Results**:
  - _Pending_

### wheels test run
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels test run`
  - With reporter: `wheels test run reporter=json`
  - With labels: `wheels test run labels=unit,integration`
- **Test Results**:
  - _Pending_

### wheels test coverage
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Generate coverage: `wheels test coverage`
  - With threshold: `wheels test coverage threshold=80`
  - Specific paths: `wheels test coverage paths=app/models`
- **Test Results**:
  - _Pending_

### wheels test debug
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Debug mode: `wheels test debug`
  - Specific test: `wheels test debug test=ProductTest`
- **Test Results**:
  - _Pending_

## Analysis Commands

### wheels analyze
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - All analyses: `wheels analyze`
  - Specific path: `wheels analyze path=app/models`
  - With report: `wheels analyze --report`
- **Test Results**:
  - _Pending_

### wheels analyze code
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels analyze code`
  - With rules: `wheels analyze code rules=complexity,naming`
  - Specific files: `wheels analyze code files=app/models/*.cfc`
- **Test Results**:
  - _Pending_

### wheels analyze performance
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels analyze performance`
  - With metrics: `wheels analyze performance metrics=queries,memory`
  - With threshold: `wheels analyze performance threshold=slow`
- **Test Results**:
  - _Pending_

### wheels analyze security
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels analyze security`
  - With severity: `wheels analyze security severity=high`
  - Specific vulnerabilities: `wheels analyze security types=sql,xss`
- **Test Results**:
  - _Pending_

## Security Commands

### wheels security
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Overview: `wheels security`
  - With report: `wheels security --report`
- **Test Results**:
  - _Pending_

### wheels security scan
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Full scan: `wheels security scan`
  - Quick scan: `wheels security scan --quick`
  - Specific paths: `wheels security scan paths=app/controllers`
- **Test Results**:
  - _Pending_

## Optimization Commands

### wheels optimize
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Auto optimize: `wheels optimize`
  - Specific optimizations: `wheels optimize types=cache,queries`
- **Test Results**:
  - _Pending_

### wheels optimize performance
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Basic: `wheels optimize performance`
  - With profile: `wheels optimize performance profile=aggressive`
  - Specific areas: `wheels optimize performance areas=database,caching`
- **Test Results**:
  - _Pending_

## Plugin Commands

### wheels plugins
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - List plugins: `wheels plugins`
  - Search: `wheels plugins search=authentication`
- **Test Results**:
  - _Pending_

### wheels plugins install
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - From ForgeBox: `wheels plugins install name=CFWheelsAuth`
  - From URL: `wheels plugins install url=https://example.com/plugin.zip`
  - Specific version: `wheels plugins install name=CFWheelsAuth version=2.0.0`
- **Test Results**:
  - _Pending_

### wheels plugins list
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - All plugins: `wheels plugins list`
  - With details: `wheels plugins list --detailed`
  - Active only: `wheels plugins list --active`
- **Test Results**:
  - _Pending_

### wheels plugins remove
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - By name: `wheels plugins remove name=CFWheelsAuth`
  - Force remove: `wheels plugins remove name=CFWheelsAuth --force`
- **Test Results**:
  - _Pending_

## Documentation Commands

### wheels docs
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Overview: `wheels docs`
  - Check status: `wheels docs status`
- **Test Results**:
  - _Pending_

### wheels docs generate
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - All docs: `wheels docs generate`
  - API docs: `wheels docs generate type=api`
  - With format: `wheels docs generate format=markdown`
- **Test Results**:
  - _Pending_

### wheels docs serve
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Default port: `wheels docs serve`
  - Custom port: `wheels docs serve port=8080`
  - With live reload: `wheels docs serve --liveReload`
- **Test Results**:
  - _Pending_

## Deployment Commands

### wheels deploy
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Deploy to production: `wheels deploy production`
  - With strategy: `wheels deploy production strategy=rolling`
- **Test Results**:
  - _Pending_

### wheels deploy init
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Initialize deployment: `wheels deploy init`
  - With provider: `wheels deploy init provider=aws`
- **Test Results**:
  - _Pending_

### wheels deploy setup
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Setup environment: `wheels deploy setup production`
  - With config: `wheels deploy setup production config=deploy.json`
- **Test Results**:
  - _Pending_

### wheels deploy push
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Push to production: `wheels deploy push production`
  - With tag: `wheels deploy push production tag=v1.0.0`
  - Dry run: `wheels deploy push production --dryRun`
- **Test Results**:
  - _Pending_

### wheels deploy rollback
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Rollback one version: `wheels deploy rollback production`
  - To specific version: `wheels deploy rollback production version=v0.9.0`
- **Test Results**:
  - _Pending_

### wheels deploy status
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Check status: `wheels deploy status production`
  - With history: `wheels deploy status production --history`
- **Test Results**:
  - _Pending_

### wheels deploy stop
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Stop deployment: `wheels deploy stop production`
  - Force stop: `wheels deploy stop production --force`
- **Test Results**:
  - _Pending_

### wheels deploy audit
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Audit deployment: `wheels deploy audit production`
  - With report: `wheels deploy audit production --report`
- **Test Results**:
  - _Pending_

### wheels deploy exec
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Execute command: `wheels deploy exec production command="ls -la"`
  - With timeout: `wheels deploy exec production command="migrate" timeout=300`
- **Test Results**:
  - _Pending_

### wheels deploy hooks
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - List hooks: `wheels deploy hooks list`
  - Add hook: `wheels deploy hooks add name=pre-deploy script=validate.sh`
  - Remove hook: `wheels deploy hooks remove name=pre-deploy`
- **Test Results**:
  - _Pending_

### wheels deploy lock
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Lock deployment: `wheels deploy lock production`
  - Unlock: `wheels deploy lock production --unlock`
  - With reason: `wheels deploy lock production reason="Maintenance"`
- **Test Results**:
  - _Pending_

### wheels deploy logs
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - View logs: `wheels deploy logs production`
  - With tail: `wheels deploy logs production --tail=100`
  - Follow logs: `wheels deploy logs production --follow`
- **Test Results**:
  - _Pending_

### wheels deploy proxy
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - Configure proxy: `wheels deploy proxy production`
  - With settings: `wheels deploy proxy production backend=app-servers`
- **Test Results**:
  - _Pending_

### wheels deploy secrets
- **Status**: ⏳ Not Tested
- **Parameters to test**:
  - List secrets: `wheels deploy secrets list production`
  - Set secret: `wheels deploy secrets set production API_KEY=value`
  - Remove secret: `wheels deploy secrets remove production API_KEY`
- **Test Results**:
  - _Pending_

## Docker Commands

### wheels docker init
- **Status**: 🚫 Disabled
- **Test Results**:
  - Command is disabled (.bak/.disabled files exist)

### wheels docker deploy
- **Status**: 🚫 Disabled
- **Test Results**:
  - Command is disabled (.bak/.disabled files exist)

## CI/CD Commands

### wheels ci init
- **Status**: 🚫 Disabled
- **Test Results**:
  - Command is disabled (.bak/.disabled files exist)

---

## Testing Notes

### General Testing Guidelines
1. Test each command in the `workspace` directory as a sandbox
2. Launch CommandBox with `box` before testing
3. Create test app with `wheels g app` first
4. Start web server with `server start`
5. Reload CommandBox with `box reload` after CLI changes
6. Remember: CommandBox doesn't mix positional and named attributes

### Common Issues to Watch For
- Syntax errors in CLI commands
- Parameter naming conventions (use `attribute=value`)
- Boolean shortcuts (use `--attribute` instead of `attribute=true`)
- Path specifications (absolute vs relative)
- Environment-specific behaviors

### Testing Progress
- Total Commands: 89 (active)
- Tested: 3
- Failed: 0
- Disabled: 5
- Remaining: 81

Last Updated: [Current Date]
