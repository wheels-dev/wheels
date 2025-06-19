# Wheels CLI Command Alias Analysis

## Commands That Are Actually Aliases

Based on my analysis of the Wheels CLI codebase, the following "missing" commands are actually aliases to existing commands:

### Aliased Commands
1. **wheels new** → `wheels generate app-wizard` (alias defined in `/cli/commands/wheels/generate/app-wizard.cfc`)
2. **wheels d** → `wheels destroy` (alias defined in `/cli/commands/wheels/destroy.cfc`)
3. **wheels r** → `wheels reload` (alias defined in `/cli/commands/wheels/reload.cfc`)
4. **wheels db latest** → `wheels dbmigrate latest` (alias defined in `/cli/commands/wheels/dbmigrate/latest.cfc`)
5. **wheels db migrate** → `wheels dbmigrate latest` (alias defined in `/cli/commands/wheels/dbmigrate/latest.cfc`)
6. **wheels db reset** → `wheels dbmigrate reset` (alias defined in `/cli/commands/wheels/dbmigrate/reset.cfc`)
7. **wheels db down** → `wheels dbmigrate down` (alias defined in `/cli/commands/wheels/dbmigrate/down.cfc`)
8. **wheels db up** → `wheels dbmigrate up` (alias defined in `/cli/commands/wheels/dbmigrate/up.cfc`)
9. **wheels db exec** → `wheels dbmigrate exec` (alias defined in `/cli/commands/wheels/dbmigrate/exec.cfc`)
10. **wheels db info** → `wheels dbmigrate info` (alias defined in `/cli/commands/wheels/dbmigrate/info.cfc`)
11. **wheels db create blank** → `wheels dbmigrate create blank` (alias defined in `/cli/commands/wheels/dbmigrate/create/blank.cfc`)
12. **wheels db create table** → `wheels dbmigrate create table` (alias defined in `/cli/commands/wheels/dbmigrate/create/table.cfc`)
13. **wheels db create column** → `wheels dbmigrate create column` (alias defined in `/cli/commands/wheels/dbmigrate/create/column.cfc`)
14. **wheels db remove table** → `wheels dbmigrate remove table` (alias defined in `/cli/commands/wheels/dbmigrate/remove/table.cfc`)
15. **wheels g snippets** → `wheels generate snippets` (alias defined in `/cli/commands/wheels/generate/snippets.cfc`)
16. **wheels g route** → `wheels generate route` (alias defined in `/cli/commands/wheels/generate/route.cfc`)
17. **wheels g api-resource** → `wheels generate api-resource` (alias defined in `/cli/commands/wheels/generate/api-resource.cfc`)
18. **wheels g model** → `wheels generate model` (alias defined in `/cli/commands/wheels/generate/model.cfc`)
19. **wheels g property** → `wheels generate property` (alias defined in `/cli/commands/wheels/generate/property.cfc`)
20. **wheels g resource** → `wheels generate resource` (alias defined in `/cli/commands/wheels/generate/resource.cfc`)
21. **wheels g test** → `wheels generate test` (alias defined in `/cli/commands/wheels/generate/test.cfc`)
22. **wheels g view** → `wheels generate view` (alias defined in `/cli/commands/wheels/generate/view.cfc`)
23. **wheels g app** → `wheels generate app` (alias defined in `/cli/commands/wheels/generate/app.cfc`)
24. **wheels g controller** → `wheels generate controller` (alias defined in `/cli/commands/wheels/generate/controller.cfc`)
25. **wheels g app-wizard** → `wheels generate app-wizard` (alias defined in `/cli/commands/wheels/generate/app-wizard.cfc`)
26. **wheels plugin list** → `wheels plugins list` (alias defined in `/cli/commands/wheels/plugins/list.cfc`)
27. **wheels t migrate** → `wheels test migrate` (alias defined in `/cli/commands/wheels/test/migrate.cfc`)

## Commands That Exist But Were Not Obviously Visible

1. **wheels scaffold** - Exists as a standalone command at `/cli/commands/wheels/scaffold.cfc`
2. **wheels test** - Exists at `/cli/commands/wheels/test.cfc` (deprecated command that defaults to app tests)

## Truly Missing Commands

The following commands appear to be genuinely missing and are not aliases:

### Base-level Commands
1. **wheels g** or **wheels generate** (without subcommand) - No generate.cfc at the root generate level
2. **wheels d scaffold** or **wheels destroy scaffold** - No scaffold subcommand under destroy
3. **wheels d resource** or **wheels destroy resource** - No resource subcommand under destroy
4. **wheels d api-resource** or **wheels destroy api-resource** - No api-resource subcommand under destroy
5. **wheels d model** or **wheels destroy model** - No model subcommand under destroy
6. **wheels d controller** or **wheels destroy controller** - No controller subcommand under destroy
7. **wheels d view** or **wheels destroy view** - No view subcommand under destroy
8. **wheels dbmigrate** (without subcommand) - No dbmigrate.cfc at the root level
9. **wheels db** (without subcommand) - No parent command for db namespace
10. **wheels server** - No server command exists
11. **wheels server start** - No server start command exists
12. **wheels server stop** - No server stop command exists
13. **wheels server status** - No server status command exists
14. **wheels server restart** - No server restart command exists
15. **wheels server log** - No server log command exists
16. **wheels server open** - No server open command exists
17. **wheels console** - No console command exists
18. **wheels plugin** (without subcommand) - Only plugins.cfc exists, not plugin.cfc
19. **wheels g mailer** or **wheels generate mailer** - No mailer generator exists
20. **wheels g job** or **wheels generate job** - No job generator exists
21. **wheels g channel** or **wheels generate channel** - No channel generator exists
23. **wheels assets** - No assets command exists
24. **wheels assets precompile** - No assets precompile command exists
25. **wheels notes** - No notes command exists
26. **wheels stats** - No stats command exists
27. **wheels time zones** or **wheels time:zones** - No time zones command exists
28. **wheels cache clear** or **wheels cache:clear** - No cache clear command exists
29. **wheels log clear** or **wheels log:clear** - No log clear command exists
30. **wheels tmp clear** or **wheels tmp:clear** - No tmp clear command exists
31. **wheels secret** - No secret command exists
32. **wheels secrets edit** or **wheels secrets:edit** - No secrets edit command exists
33. **wheels credentials edit** or **wheels credentials:edit** - No credentials edit command exists
34. **wheels restart** - While 'wheels reload' exists, no restart command exists
35. **wheels middleware** - No middleware command exists
36. **wheels runner** - No runner command exists
37. **wheels plugin update** or **wheels plugin upgrade** - Only install, list, and remove exist
38. **wheels plugin search** - No search subcommand under plugins
39. **wheels plugin show** or **wheels plugin info** - No show/info subcommand under plugins

## Partial Implementations

Some commands exist but appear to be missing expected subcommands based on Rails conventions:

1. **wheels destroy** - Exists but only as a base command, missing all the generator counterparts (scaffold, resource, model, controller, view, etc.)
2. **wheels test** - Has the deprecated base command plus coverage, debug, migrate, and run subcommands
3. **wheels plugins** - Has install, list, and remove, but missing update/upgrade and search functionality

## Summary

- **27 commands** that appeared to be missing are actually aliases to existing commands
- **2 commands** exist but were not immediately obvious (scaffold and test)
- **38 commands** are truly missing from the implementation
- **3 command namespaces** have partial implementations compared to Rails conventions

The aliasing system in Wheels CLI is quite extensive, with many shortcuts like `wheels g` for `wheels generate` and `wheels db` for `wheels dbmigrate`. However, there are still significant gaps in functionality compared to the Rails CLI that Wheels is inspired by.