# Changelog

All notable changes to this project will be summarized in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

# [3.0.0-SNAPSHOT](https://github.com/wheels-dev/wheels/tree/develop) => TBD

### Controller Enhancements

### Model Enhancements
- PR-1326-ignoreColumns model config method [#1326](https://github.com/cfwheels/cfwheels/pull/1326) - [Adam Chapman](https://github.com/chapmandu)
- PR-1568-issue #432 improved model initialization to handle race conditions with better error handling and automatic recovery [#1568](https://github.com/wheels-dev/wheels/pull/1568) - [Zain Ul Abideen](https://github.com/zainforbjs)

### View Enhancements

### Bug Fixes
- PR-1327-issue #1319 model datasource bug [#1327](https://github.com/cfwheels/cfwheels/pull/1327) - [Adam Chapman](https://github.com/chapmandu)
- PR-1360-updateAll() is missing JOIN statement(s) when passing a value for the include argument [#1360](https://github.com/cfwheels/cfwheels/pull/1360) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Miscellaneous
- PR-1316-Feature/fix testui container [#1316](https://github.com/cfwheels/cfwheels/pull/1316) - [Peter Amiri](https://github.com/bpamiri)
- PR-1328-Backport datasource changes to develop branch [#1328](https://github.com/cfwheels/cfwheels/pull/1328) - [Peter Amiri](https://github.com/bpamiri)
- PR-1329-use github build vars to remove the hardcoded version number [#1329](https://github.com/cfwheels/cfwheels/pull/1329) - [Peter Amiri](https://github.com/bpamiri)
- PR-1317-Rewrite the Vue based TestUI app [#1317](https://github.com/cfwheels/cfwheels/pull/1317) - [Zain Ul Abideen](https://github.com/zainforbjs)

### Guides
- PR-1304-Update beginner-tutorial-hello-database.md [#1304](https://github.com/cfwheels/cfwheels/pull/1304) - [MvdO79](https://github.com/MvdO79)
- PR-1305-Update beginner-tutorial-hello-database.md [#1305](https://github.com/cfwheels/cfwheels/pull/1305) - [MvdO79](https://github.com/MvdO79)
- PR-1308-Added: "Nested queries not allowed" in WHERE clause documentation [#1308](https://github.com/cfwheels/cfwheels/pull/1308) - [MvdO79](https://github.com/MvdO79)
- PR-1313-Spelling checks [#1313](https://github.com/cfwheels/cfwheels/pull/1313) - [MvdO79](https://github.com/MvdO79)
- PR-1323-Update guides with description of the templates directory [#1323](https://github.com/cfwheels/cfwheels/pull/1323) - [MvdO79](https://github.com/MvdO79)
- PR-1350-Update documentation for  Reading Rrecords [#1350](https://github.com/cfwheels/cfwheels/pull/1350) - [MvdO79](https://github.com/MvdO79)
- PR-1355-Add examples for IgnoredColumns attribute by creating ignoredcolumns.txt [#1355](https://github.com/cfwheels/cfwheels/pull/1355) - [MvdO79](https://github.com/MvdO79)

### Potentially Breaking Changes
- PR-1240-Feature/move wheels outside the app root and make changes to mappings [#1240](https://github.com/cfwheels/cfwheels/pull/1240) - [Zain Ul Abideen](https://github.com/zainforbjs)
- PR-1310-update paths in application.cfm [#1310](https://github.com/cfwheels/cfwheels/pull/1310) - [Peter Amiri](https://github.com/bpamiri)
- PR-1314-Added some missing mappings [#1314](https://github.com/cfwheels/cfwheels/pull/1314) - [Zain Ul Abideen](https://github.com/zainforbjs)

---

# [2.5.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.5.0) => 2023.11.01

<!-- ### Controller Enhancements -->

### Model Enhancements
- PR-1183-Allow datasource argument in finders [#1183](https://github.com/cfwheels/cfwheels/pull/1183) - [Adam Chapman]
- PR-1201-Issue #929 validate not nullable columns with default [#1201](https://github.com/cfwheels/cfwheels/pull/1201) - [Adam Chapman]
- PR-1202-Remove old oracle test workaround [#1202](https://github.com/cfwheels/cfwheels/pull/1202) - [Adam Chapman]
- PR-1205-issue-1182-adds-simplelock-to-sql-caching [#1205](https://github.com/cfwheels/cfwheels/pull/1205) - [Adam Chapman]
- PR-1222-Findall() performance bottleneck [#1222](https://github.com/cfwheels/cfwheels/pull/1222) - [Adam Chapman]
- PR-1223-refactor-queryCallback-with-inbuilt-query-functions [#1223](https://github.com/cfwheels/cfwheels/pull/1223) - [Adam Chapman]
- PR-1226-Invalid column not throwing exception in select argument [#1226](https://github.com/cfwheels/cfwheels/pull/1226) - [Zain Ul Abideen]
- PR-1265-improve-performance-refactor-out-listfind [#1265](https://github.com/cfwheels/cfwheels/pull/1265) -  [Adam Chapman]
- PR-1260-Adds support for native query returnType [#1260](https://github.com/cfwheels/cfwheels/pull/1260) - [Adam Chapman]
- PR-1249-Removed the original IF/ELSE condition that invalidates calculated props and added condition [#1240](https://github.com/cfwheels/cfwheels/pull/1249) - [Zain Ul Abideen]

### View Enhancements
- PR-1254-issue 908 enable paginationLinks() to set active class on parent [#1254](https://github.com/cfwheels/cfwheels/pull/1254) - [Zain Ul Abideen]

### Bug Fixes
- PR-1227-Return a numeric value if the primary key is Numeric [#1227](https://github.com/cfwheels/cfwheels/pull/1227) - [Zain Ul Abideen]
- PR-1257-Checkbox bug when checkedvalue is not true [#1257](https://github.com/cfwheels/cfwheels/pull/1257) - [Adam Chapman]
- PR-1246-set the default route if it is not passed in the function [#1246](https://github.com/cfwheels/cfwheels/pull/1246) - [Zain Ul Abideen]
- PR-1256-issue 889 unable to duplicate component [#1256](https://github.com/cfwheels/cfwheels/pull/1256) - [Zain Ul Abideen]
- PR-1253-Issue 580 select ambiguous column name using the wheels alias [#1253](https://github.com/cfwheels/cfwheels/pull/1253) - [Zain Ul Abideen]
- PR-1245-Added afterFind callback hook in the findAll function in case of structs [#1245](https://github.com/cfwheels/cfwheels/pull/1245) - [Zain Ul Abideen]
- PR-1302-Check for Reload Password when setting a url IP exception [#1302](https://github.com/cfwheels/cfwheels/pull/1302) - Peter Amiri

### Miscellaneous
- PR-1175-restoreTestRunnerApplicationScope setting [#1175](https://github.com/cfwheels/cfwheels/pull/1175) - [Adam Chapman]
- PR-1176-fix text in core readme file [#1176](https://github.com/cfwheels/cfwheels/pull/1176) - [Per Djurner]
- PR-1177-fix text in base template readme file [#1177](https://github.com/cfwheels/cfwheels/pull/1177) - [Per Djurner]
- PR-1178-fix text in default template file [#1178](https://github.com/cfwheels/cfwheels/pull/1178) - [Per Djurner]
- PR-1185-adds-root-docker-volume [#1185](https://github.com/cfwheels/cfwheels/pull/1185) - [Adam Chapman]
- PR-1200-Update the docker-compose command to docker compose v2 syntax [#1200](https://github.com/cfwheels/cfwheels/pull/1200/) - [Adam Chapman, Peter Amiri]
- PR-1204-Add Lucee 6 to test matrix on local Docker test suite [#1204](https://github.com/cfwheels/cfwheels/pull/1204/) - [Peter Amiri]
- PR-1203-ensure testing params maintained [#1203](https://github.com/cfwheels/cfwheels/pull/1203) - [Adam Chapman]
- PR-1228-Adding addClass attribute in the function textField [#1228](https://github.com/cfwheels/cfwheels/pull/1228) - [Zain Ul Abideen]
- PR-1230-Add Adobe 2021 Support to local Docker and GitHub Actions testing - [#1230](https://github.com/cfwheels/cfwheels/pull/1230) - Peter Amiri
- PR-1264-update Lucee 6 version used for tests to latest [#1264](https://github.com/cfwheels/cfwheels/pull/1264) - [Zac Spitzer -  * *New Contributor* *]
- PR-1241-Fix spelling and remove whitespace from link [#1241](https://github.com/cfwheels/cfwheels/pull/1241) - [John Bampton]
- PR-1247-show the current git branch in the debug layout [#1247](https://github.com/cfwheels/cfwheels/pull/1247) - [Michael Diederich]
- PR-1250-Added test framework functions in the docs [#1250](https://github.com/cfwheels/cfwheels/pull/1250) - [Zain Ul Abideen]
- PR-1255-issue 1179 Downloaded the CDN files and changed paths in files [#1255](https://github.com/cfwheels/cfwheels/pull/1255) - [Zain Ul Abideen]

### Guides
- PR-1198-Documentation-fixes [#1198](https://github.com/cfwheels/cfwheels/pull/1198) - [Adam Chapman]

<!-- ### Potentially Breaking Changes -->

----

# [2.4.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.4.0%2B1) => 2022.08.17

<!-- ### Controller Enhancements -->

<!-- ### Model Enhancements -->

<!-- ### View Enhancements -->

### Bug Fixes
- issue-1091-wheels-paths-in-error-template [#1091](https://github.com/cfwheels/cfwheels/issues/1091) - [Adam Chapman]
- issue-1082-validations should not trim properties [#1082](https://github.com/cfwheels/cfwheels/issues/1082) - [Adam Chapman]
- issue-1088-Adds SQL parsing regex tweak which correctly handles whitespace [#1088](https://github.com/cfwheels/cfwheels/issues/1088) - [Adam Chapman, Adam Cameron]

### Miscellaneous
- Adds cfformat ignore marker comments around core "view" cfm files that contain html markup - [Adam Chapman]
- Adds the ability to scroll large items horizontally in the test runner UI [#1130](https://github.com/cfwheels/cfwheels/pull/1130) - [Adam Chapman]
- Fix cfformat ignore markers [#1129](https://github.com/cfwheels/cfwheels/pull/1129) - [Adam Chapman]
- Enable finder model methods to returnAs "sql", mainly for debugging [#1141](https://github.com/cfwheels/cfwheels/pull/1141) - [Adam Chapman]
- Show the Test Runner buttons in the CFWheels GUI on the Package List screen allowing the developer to run the entire test suite instead of one package at a time. - [Peter Amiri]
- The Base Template now contains all necessary placeholders for the CLI to interact with the application and be able to inject code properly. - [Peter Amiri]
- By default the Core tests will run in the application datasource, but the developer can setup a different database for running the Core tests to ensure there is no side effects from running the tests. If you do end up setting a different database for the coreTestDatasourceName, make sure to reload your application after running the Core tests. - [Peter Amiri]
- Fix two broken links in README. [#1150] - [John Bampton -  * *New Contributor* *]
- Fix spelling [#1151][#1158] - [John Bampton -  * *New Contributor* *]
- Add .env parser to parse .env files and add the properties found in the file to this.env scope. [#1157](https://github.com/cfwheels/cfwheels/pull/1157) - [Peter Amiri]
- Update the local test suite to supported ARM architecture docker images to make the suite compatible with the Apple Silicon Macs. [#1143](https://github.com/cfwheels/cfwheels/pull/1143) - [Peter Amiri]

### Guides
- Fix broken links throughout the guides. - [Peter Amiri]
- Fixed mailto link in CONTRIBUTING.md [#1123](https://github.com/cfwheels/cfwheels/pull/1123) - [Coleman Sperando * *New Contributor* *]
- Fix test guides examples [#1125](https://github.com/cfwheels/cfwheels/pull/1125) [Adam Chapman]
- Fix typos in the guides [#1161](https://github.com/cfwheels/cfwheels/pull/1161) [Adam Chapman]

<!-- ### Potentially Breaking Changes -->

----

# [2.3.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.3.0) => 2020.05.11

This release finalizes the 2.3.0 release and doesn't include any new enhancements or bug fixes. Below is the change log from the 2.3.0.rc.1 release.

### View Enhancements
- Adds association error support via `includeAssociations` argument [#1080](https://github.com/cfwheels/cfwheels/issues/1080) - [Nikolaj Frey]

### Bug Fixes

- onerror handler should increase user defined requestTimeout value [#1056](https://github.com/cfwheels/cfwheels/issues/1056) - [Adam Chapman]
- deletedAt should also respect timestamp mode (UTC) [#1063](https://github.com/cfwheels/cfwheels/issues/1063) - [David Belanger]
- Fixes No output from `Debug()` usage in plugin test cases [#1061](https://github.com/cfwheels/cfwheels/issues/1063) - [Tom King]
- Development mode will now properly return a 404 status if view not found [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- 404 status now properly returned without URL rewriting [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- Internal Docs in ACF2018 should now not display duplicate categories [Tom King]
- Internal Docs search now resets itself properly on backspace with empty value [#982](https://github.com/cfwheels/cfwheels/issues/982) - [Brandon Shea, Tom King]
- `ValidatesConfirmationOf()` now correctly enforces prescence of confirmation property [#1070](https://github.com/cfwheels/cfwheels/issues/1070) - [Adam Cameron, Tom King]
- `resource()`/`resources()` now allows empty `only` property to utilise as non-route parent [#1083](https://github.com/cfwheels/cfwheels/issues/1083) - [Brian Ramsey]
- Handle XSS Injection in development environment - [Michael Diederich]
- Fix params bug in CLI API [#1106] - [Peter Amiri]

### Miscellaneous

- Update Docker Lucee Commandbox version to 5.2.0 - [Adam Chapman, Tom King]
- Minor internal obsolete reference to modelComponentPath removed - [Adam Chapman, Tom King]
- Minor visual fix for long migration logs overflow in modal (scroll) - [Brian Ramsey]
- Add test suite for Lucee and H2 Database to the GitHub Actions test suite. - [Peter Amiri]
- On going changes to update the H2 drivers [#1107] - [Peter Amiri]
- Fixes some syntax formatting introduced by cfformat [#1111] - [Adam Chapman]
- Minimum ColdFusion version is now ColdFusion (2018 release) Update 3 (2018,0,03,314033) / ColdFusion (2016 release) Update 10 (2016,0,10,314028) / ColdFusion 11 Update 18 (11,0,18,314030) [#923](https://github.com/cfwheels/cfwheels/issues/923) - [Michael Diederich]
- Wheels save(allowExplicitTimestamps=true) doesn't produce the expected result [#1113] - [SebastienFCT]

### Potentially Breaking Changes

- Automatic Time Stamps: the **deletedAt** column was using the server's local time for the timestamp while **createdAt** / **updatedAt** were using the timestamp selected for the timestamp mode. The default for CFWheels' timestamp mode is UTC and therefore all future **deletedAt** timestamps will be in UTC unless you've changed the default.  Please review any SQL that uses **deletedAt** for datetime comparison.

----

# [2.3.0-rc.1](https://github.com/cfwheels/cfwheels/releases/tag/v2.3.0-rc.1) => 2020.05.03

<!-- ### Controller Enhancements -->

<!-- ### Model Enhancements -->

### View Enhancements
- Adds association error support via `includeAssociations` argument [#1080](https://github.com/cfwheels/cfwheels/issues/1080) - [Nikolaj Frey]

### Bug Fixes

- onerror handler should increase user defined requestTimeout value [#1056](https://github.com/cfwheels/cfwheels/issues/1056) - [Adam Chapman]
- deletedAt should also respect timestamp mode (UTC) [#1063](https://github.com/cfwheels/cfwheels/issues/1063) - [David Belanger]
- Fixes No output from `Debug()` usage in plugin test cases [#1061](https://github.com/cfwheels/cfwheels/issues/1063) - [Tom King]
- Development mode will now properly return a 404 status if view not found [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- 404 status now properly returned without URL rewriting [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - [Adam Cameron, Tom King]
- Internal Docs in ACF2018 should now not display duplicate categories [Tom King]
- Internal Docs search now resets itself properly on backspace with empty value [#982](https://github.com/cfwheels/cfwheels/issues/982) - [Brandon Shea, Tom King]
- `ValidatesConfirmationOf()` now correctly enforces prescence of confirmation property [#1070](https://github.com/cfwheels/cfwheels/issues/1070) - [Adam Cameron, Tom King]
- `resource()`/`resources()` now allows empty `only` property to utilise as non-route parent [#1083](https://github.com/cfwheels/cfwheels/issues/1083) - [Brian Ramsey]
- Handle XSS Injection in development environment - [Michael Diederich]
- Fix params bug in CLI API [#1106] - [Peter Amiri]

### Miscellaneous

- Update Docker Lucee Commandbox version to 5.2.0 - [Adam Chapman, Tom King]
- Minor internal obsolete reference to modelComponentPath removed - [Adam Chapman, Tom King]
- Minor visual fix for long migration logs overflow in modal (scroll) - [Brian Ramsey]
- Add test suite for Lucee and H2 Database to the GitHub Actions test suite. - [Peter Amiri]
- On going changes to update the H2 drivers [#1107] - [Peter Amiri]
- Fixes some syntax formatting introduced by cfformat [#1111] - [Adam Chapman]
- Minimum ColdFusion version is now ColdFusion (2018 release) Update 3 (2018,0,03,314033) / ColdFusion (2016 release) Update 10 (2016,0,10,314028) / ColdFusion 11 Update 18 (11,0,18,314030) [#923](https://github.com/cfwheels/cfwheels/issues/923) - [Michael Diederich]
- Wheels save(allowExplicitTimestamps=true) doesn't produce the expected result [#1113] - [SebastienFCT]

### Potentially Breaking Changes

- Automatic Time Stamps: the **deletedAt** column was using the server's local time for the timestamp while **createdAt** / **updatedAt** were using the timestamp selected for the timestamp mode. The default for CFWheels' timestamp mode is UTC and therefore all future **deletedAt** timestamps will be in UTC unless you've changed the default.  Please review any SQL that uses **deletedAt** for datetime comparison.

----

<a name="2.2"></a>

# [2.2](https://github.com/cfwheels/cfwheels/releases/tag/v2.2.0) => 2020.11.22

### Controller Enhancements

- Added the `status` argument to all `render*()` functions to force returning a specific HTTP status code [#1025](https://github.com/cfwheels/cfwheels/issues/1025) - [Adam Chapman, Tom King]
- CORS `accessControlAllowOrigin` can now match subdomain wildcards [#1031](https://github.com/cfwheels/cfwheels/issues/1031) - [Tom King]

### Model Enhancements

- Experimental adapter for Oracle database - [Andrei B]
- Added `automaticValidations` argument to the `property` method - [Per Djurner]
- Support named second argument in `findOneBy[Property]And[Property]` and `findAllBy[Property]And[Property]` - [Per Djurner]
- Support `value` argument in `findOrCreateBy[Property]` - [Per Djurner]
- Minor fix for `full null support` - [Michael Diederich]

### View Enhancements

- Added the `required` argument to `imageTag` to suppress exceptions if using non-existent files [#979](https://github.com/cfwheels/cfwheels/issues/979) - [Adam Chapman, Michael Diederich]

### Bug Fixes

- Removed authenticity token id attribute to avoid non-unique id warnings in Chrome [#953](https://github.com/cfwheels/cfwheels/issues/953) - [Per Djurner]
- Fixes regular expression bug when using the SQL `IN` operator [#944](https://github.com/cfwheels/cfwheels/issues/944) - [Adam Chapman, Per Djurner]
- Display content in maintenance mode on newer Lucee versions [#848](https://github.com/cfwheels/cfwheels/issues/848) - [Per Djurner]
- `validatesUniquenessOf` does not respect allowBlank [#914](https://github.com/cfwheels/cfwheels/issues/914) - [Adam Chapman]
- `Wheels.RouteNotFound` Error page now escapes the `arguments.path` to prevent XSS attacks - [Michael Diederich]
- `buttonTo()` now uses `<button>` internally instead of `<input>` allowing for html in content - [#798](https://github.com/cfwheels/cfwheels/issues/798) - [Tom Sucaet, Tom King, Per Djurner]
- Minor SQL preview fix in GUI - [#992](https://github.com/cfwheels/cfwheels/issues/992) - [Brandon Shea, Tom King]

### Miscellaneous

- Added the `refresh` url parameter for auto refreshing test framework html - [#986](https://github.com/cfwheels/cfwheels/issues/986) - [Adam Chapman]
- Allow custom migrator templates by scanning the `/migrator/templates` directory - [Adam Chapman]
- Minimum Lucee 5 version is now 5.3.2.77 - Tests added - [Michael Diederich]
- Use `http_x_forwarded_proto` to determine if the application is running behind a loadbalancer that is performing SSL offloading - [Peter Amiri]
- Allow the combination of `url` and `params` arguments with `redirectTo` - [Adam Chapman]
- Fixed some variable scoping - [Michael Diederich]
- Github Actions CI Pipeline - [Adam Chapman, Tom King]
- Flash Cookie can now be disabled via `set(flashStorage="none")` [#978](https://github.com/cfwheels/cfwheels/issues/978) [Tom King]
- `processRequest()` accepts a route param -[#1030](https://github.com/cfwheels/cfwheels/issues/1030) - [Adam Chapman]
- Migration files are written with 664 mode -[#1034](https://github.com/cfwheels/cfwheels/issues/1034) - [Adam Chapman]

----

<a name="2.1"></a>

# [2.1](https://github.com/cfwheels/cfwheels/releases/tag/v2.1.0) => 2020.04.12

### Bug Fixes

- Fixed pagination order ambiguous column name exception - [#980](https://github.com/cfwheels/cfwheels/issues/#980) [Adam Chapman, Mike Lange]
- Renames findLast() to findLastOne() for lucee5.3.5+92 upwards compatibility [#988](https://github.com/cfwheels/cfwheels/issues/#988)

----

<a name="2.1.0-beta"></a>

# [2.1.0-Beta](https://github.com/cfwheels/cfwheels/releases/tag/v2.1.0-beta) => 2020.02.24

### Potentially Breaking Changes

- The new CFWheels internal GUI is more isolated and runs in it's own component: previously this was extending the developers main `Controller.cfc` which caused multiple issues. The migrator, test runner and routing GUIs have therefore all been re-written.
- The plugins system behaviour no longer chains multiple functions of the same name as this was a major performance hit. It's recommended that plugin authors check their plugins to run on 2.1
- HTTP Verb/Method switching is now no longer allowed via GET requests and must be performed via POST (i.e via `_method`)

### Model Enhancements

- Migrator now automatically manages the timestamp columns on `addRecord()` and `updateRecord()` calls - [#852](https://github.com/cfwheels/cfwheels/pull/852) [Charley Contreras]
- Migrator correctly honors CFWheels Timestamp configuration settings (`setUpdatedAtOnCreate, softDeleteProperty, timeStampMode, timeStampOnCreateProperty, timeStampOnUpdateProperty`) - [#852](https://github.com/cfwheels/cfwheels/pull/852) [Charley Contreras]
- `MSSQL` now uses `NVARCHAR(max)` instead of `TEXT` [#896](https://github.com/cfwheels/cfwheels/pull/896) [Reuben Brown]
- Allow createdAt and updatedAt to be explicitly assigned using the `allowExplicitTimestamps=true` argument - [#887](https://github.com/cfwheels/cfwheels/issues/887) - [Adam Chapman]

### Controller Enhancements

- New `set(flashAppend=true)` option allows for appending of a Flash key instead of replacing - [#855](https://github.com/cfwheels/cfwheels/pull/855) - [Tom King]
- `flashMessages()` now checks for an array of strings or just a string and outputs appropriately - [#855](https://github.com/cfwheels/cfwheels/pull/855) - [Tom King]
- `flashInsert()` can now accept a one dimensional array - [#855](https://github.com/cfwheels/cfwheels/pull/855) - [Tom King]

### Bug Fixes

- Allow uppercase table names containing reserved substrings like `OR` and `AND` - [#765](https://github.com/cfwheels/cfwheels/issues/765) [Dmitry Yakhnov, Adam Chapman]
- Calculated properties can now override an existing property - [#764](https://github.com/cfwheels/cfwheels/issues/764) [Adam Chapman, Andy Bellenie]
- Filters are now correctly called if there is more than one after filter - [#853](https://github.com/cfwheels/cfwheels/issues/853) [Brandon Shea, Tom King, Adam Chapman]
- Minor fix for duplicate debug output in the test suite - [#176](https://github.com/cfwheels/cfwheels/issues/176) [Adam Chapman, Tom King]
- Convert `handle` to a valid variable name so it doesn't break when using dot notation - [#846](https://github.com/cfwheels/cfwheels/issues/846) [Per Djurner]
- The `validatesUniquenessOf()` check now handles cases when duplicates already exist - [#480](https://github.com/cfwheels/cfwheels/issues/480) [Randall Meeker, Per Djurner]
- `validatesConfirmationOf()` now has a `caseSensitive` argument to optionally perform a case sensitive comparison - [#918](https://github.com/cfwheels/cfwheels/issues/918) [Tom King]
- `sendFile()` no longer expands an already expanded directory on ACF2016 - [#873](https://github.com/cfwheels/cfwheels/issues/873) [David Paul Belanger, Tom King, strubenstein]
- Automatic database migrations onApplicationStart now correctly reference appropriate Application scope - [#870](https://github.com/cfwheels/cfwheels/issues/870) [Tom King]
- `usesLayout()` now can be called more than once and properly respects the order called - [#891](https://github.com/cfwheels/cfwheels/issues/891) [David Paul Belanger]
- Migrator MSSQL adapter now respects `Time` and `Timestamp` Column Types - [#906](https://github.com/cfwheels/cfwheels/issues/906) [Reuben Brown]
- Automatic migrations fail on application start - [#913](https://github.com/cfwheels/cfwheels/issues/913) [Adam Chapman]
- Default `cacheFileChecking` to `true` in development mode - [Adam Chapman, Steve Harvey]
- Migrator columnNames list values are now trimmed - [#919](https://github.com/cfwheels/cfwheels/issues/#919) [Adam Chapman]
- Fixes bug when httpRequestData content is a JSON array - [#926](https://github.com/cfwheels/cfwheels/issues/#926) [Adam Chapman]
- When httpRequestData content is a JSON array, contents are now automatically added to `params._json` - [#939](https://github.com/cfwheels/cfwheels/issues/#939) [Tom King]
- Fixes bug where Migrator \$execute() always appends semi-colon - [#924](https://github.com/cfwheels/cfwheels/issues/#924) [Adam Chapman]
- Fixes bug where model createdAt property is changed upon update - [#927](https://github.com/cfwheels/cfwheels/issues/#927) [Brandon Shea, Adam Chapman]
- Fixed silent application.wheels scope exception hampering autoMigrateDatabase - [#957](https://github.com/cfwheels/cfwheels/issues/#957) [Adam Chapman, Tom King]

### Miscellaneous

- Added the ability to pass `&lock=false` in the URL for when reload requests won't work due to locking - [Per Djurner]
- Basic 302 redirects now available in mapper via `redirect` argument for `GET/PUT/PATCH/POST/DELETE` - [#847](https://github.com/cfwheels/cfwheels/issues/847) - [Tom King]
- `.[format]` based routes can now be turned off in `resources()` and `resource()` via `mapFormat=false` - [#899](https://github.com/cfwheels/cfwheels/issues/899) - [Tom King]
- `mapFormat` can now be set as a default in `mapper()` for all child `resources()` and `resource()` calls - [#899](https://github.com/cfwheels/cfwheels/issues/899) - [Tom King]
- `HEAD` requests are now aliased to `GET` requests [#860](https://github.com/cfwheels/cfwheels/issues/860) - [Tom King]
- Added the `includeFilters` argument to the `processRequest` function for skipping execution of filters during controller unit tests - [Adam Chapman]
- Added the `useIndex` argument to finders for adding table index hints [#864](https://github.com/cfwheels/cfwheels/issues/864) - [Adam Chapman]
- HTTP Verb/Method switching is now no longer allowed via `GET` requests and must be performed via `POST` [#886](https://github.com/cfwheels/cfwheels/issues/886) - [Tom King]
- CORS Header `Access-Control-Allow-Origin` can now be set either via a simple value or list in `accessControlAllowOrigin()` [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- CORS Header `Access-Control-Allow-Methods` can now be set via `accessControlAllowMethods(value)` [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- CORS Header `Access-Control-Allow-Credentials` can now be turned on via `accessControlAllowCredentials(true)`; [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- `accessControlAllowMethodsByRoute()` now allows for automatic matching of available methods for a route and sets CORS Header `Access-Control-Allow-Methods` appropriately [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- CORS Header can now be set via `accessControlAllowHeaders(value)` [#888](https://github.com/cfwheels/cfwheels/issues/888) [Tom King]
- Performance Improvement: Scanning of Models and Controllers [#917](https://github.com/cfwheels/cfwheels/issues/917) [Adam Chapman]
- Added the `authenticityToken()` function for returning the raw CSRF authenticity token [#925](https://github.com/cfwheels/cfwheels/issues/925) [Adam Chapman]
- Adds `enablePublicComponent`, `enableMigratorComponent`,`enablePluginsComponent` environment settings to completely disable those features [#926](https://github.com/cfwheels/cfwheels/issues/936) [Tom King]
- New CFWheels Internal GUI [#931](https://github.com/cfwheels/cfwheels/issues/931) [Tom King]
- `pluginRunner()` now removed in favour of 1.x plugin behaviour for performance purposes [#916](https://github.com/cfwheels/cfwheels/issues/916) [Core Team]
- Adds `validateTestPackageMetaData` environment setting for skipping test package validation on large test suites [#950](https://github.com/cfwheels/cfwheels/issues/950) [Adam Chapman]
- Added aliases for `migrator.TableDefinition` functions to allow singular variant of the `columnNames` property [#922](https://github.com/cfwheels/cfwheels/issues/922) [Sébastien FOCK CHOW THO]
- `onAbort` is now supported via `events/onabort.cfm` [#962](https://github.com/cfwheels/cfwheels/issues/962) [Brian Ramsey]

----

<a name="2.0.1"></a>

# [2.0.1](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.1) => 2018.01.31

### Bug Fixes

- Fixes reload links on application test suite page - [#820](https://github.com/cfwheels/cfwheels/issues/820) [Michael Diederich]
- Set `dbname` in `cfdbinfo` calls when using custom database connection string - [#822](https://github.com/cfwheels/cfwheels/issues/822) [Per Djurner]
- Fixes `humanize()` function - [#663](https://github.com/cfwheels/cfwheels/issues/663) [Chris Peters, Per Djurner, kmd1970]
- Enables the `rel` attribute for `stylesheetlinkTag()` - [#834](https://github.com/cfwheels/cfwheels/pull/834) [Michael Diederich]
- Returning a `NULL` value from a query with NULL support enabled no longer throws an error - [#834](https://github.com/cfwheels/cfwheels/pull/834) [Michael Diederich]
- Accessing a route with incorrect verb now provides a more useful error message - [#800](https://github.com/cfwheels/cfwheels/issues/800) [Tom King]
- Fixed bug with arrays in URLs - [#836](https://github.com/cfwheels/cfwheels/issues/836) [Michael Diederich, Per Djurner]
- startFormTag now properly applies the method attribute - [#837](https://github.com/cfwheels/cfwheels/issues/837) [David Paul Belanger]
- Incompatible plugin notice now ignores patch releases unless specified - [#840](https://github.com/cfwheels/cfwheels/issues/840) [Risto, Tom King]

----

<a name="2.0.0"></a>

# [2.0.0](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.0) => 2017.09.30

### Bug Fixes

- Support passing in `encode="attributes"` to `submitTag()`, `buttonTag()`, `paginationLinks()`, `checkBoxTag()`, and `checkBox()` - [#816](https://github.com/cfwheels/cfwheels/issues/816) [Per Djurner, Tom King]
- Support passing in `encode="attributes"` to date helpers - [#818](https://github.com/cfwheels/cfwheels/issues/818) [Per Djurner]

### Breaking Changes

- Support for Oracle has been dropped.

----

<a name="2.0.0-rc.1"></a>

# [2.0.0 RC 1](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.0-rc.1) => 08/21/2017.08.21

### Model Enhancements

- Added global setting (`createMigratorTable`) for creating migrations table - [#796](https://github.com/cfwheels/cfwheels/issues/796) [Adam Chapman, Per Djurner]

### View Enhancements

- Use association to create automatic property labels on `belongsTo()` - [#618](https://github.com/cfwheels/cfwheels/issues/618) [Andy Bellenie, Chris Peters]
- The output of all view helpers is now encoded by default - [#777](https://github.com/cfwheels/cfwheels/issues/777) [Per Djurner]

### Controller Enhancements

- Added global setting (`allowCorsRequests`) for allowing CORS requests to go through - [#623](https://github.com/cfwheels/cfwheels/issues/623) [Chris Peters, David Belanger, Per Djurner, Tom King]

### Bug Fixes

- Support CSRF in `buttonTo()` - [#808](https://github.com/cfwheels/cfwheels/issues/808) [Per Djurner, Tom King]
- Fix encoding on `buttonTo()` - [#798](https://github.com/cfwheels/cfwheels/issues/798) [Per Djurner]
- Fix error when creating default table for migrations - [#791](https://github.com/cfwheels/cfwheels/issues/791) [Adam Chapman, Per Djurner]
- Fix so calling `usesLayout()` in `Controller.cfc` does not affect layout of internal CFWheels pages - [#793](https://github.com/cfwheels/cfwheels/issues/793) [Adam Chapman, Per Djurner]
- Fix slow performance of findAll - [#806](https://github.com/cfwheels/cfwheels/issues/806) [Andy Bellenie]

### Breaking Changes

- Minimum version when running Lucee 5 is now 5.2.1.9 (can be disabled with the `disableEngineCheck` setting).
- Minimum version when running ACF 2016 is now 2016,0,04,302561 (can be disabled with the `disableEngineCheck` setting).
- includePartial() now requires the `partial` and `query` arguments to be set (if using a query)

----

<a name="2.0.0-beta.1"></a>

# [2.0.0 Beta 1](https://github.com/cfwheels/cfwheels/releases/tag/v2.0.0-beta.1) => 2017.05.31

### Model Enhancements

- Support for passing in `select=false` to `property()` to not include a calculated property by default in SELECT clauses - [#122](https://github.com/cfwheels/cfwheels/issues/122) [Adam Chapman, Per Djurner]
- Support for setting calculated properties to a specific data type - [Per Djurner]
- Support for boolean `returnIncluded` argument in `properties()` for returning nested properties - [Adam Chapman]
- Support for calling `updateProperty()` with dynamic argument, e.g. `updateProperty(firstName="Per")` - [Per Djurner]
- Support for using boolean transaction argument, e.g. `update(transaction=false)` - [#654](https://github.com/cfwheels/cfwheels/issues/654) [Adam Chapman]
- Model instance `isPersisted()` and `propertyIsBlank()` methods - [#559](https://github.com/cfwheels/cfwheels/issues/559) [Chris Peters]
- Database Migrations (dbmigrate) now available in the core (See Breaking Changes) - [#664](https://github.com/cfwheels/cfwheels/issues/664) [Adam Chapman, Tom King, Mike Grogan]
- Databases can now be automatically migrated to the latest version on application start - [#766](https://github.com/cfwheels/cfwheels/issues/766) [Tom King]
- New `timeStampMode` setting (`"utc"`, `"local"` or `"epoch"`) for the `createdAt` and `updatedAt` columns - [Andy Bellenie]
- Allow nested transactions - [#732](https://github.com/cfwheels/cfwheels/issues/732) [Andy Bellenie]
- The `handle` argument to finders now set the variable name for the query so it's easier to find in the debug output - [Per Djurner]
- Support added for HAVING when using aggregate functions in the `where` argument - [#483](https://github.com/cfwheels/cfwheels/issues/483) [Per Djurner]
- Added support for the JSON data type in the MySQL adapter - [#759](https://github.com/cfwheels/cfwheels/issues/759) [Joel Stobart]
- Corrected mapping for text types in the MySQL adapter - [#759](https://github.com/cfwheels/cfwheels/issues/759) [Joel Stobart]
- Added global setting, `lowerCaseTableNames`, to always lower case table names in SQL statements - [Per Djurner]

### View Enhancements

- `flashMessages()` are now in default layout.cfm - [#650](https://github.com/cfwheels/cfwheels/issues/650) [Tom King]
- Added ability to override value in `textField()`, `passwordField()` and `hiddenField()` - [#633](https://github.com/cfwheels/cfwheels/issues/633) [Per Djurner, Chris Peters]
- Support for the `method` argument in `buttonTo()` helper - [#761](https://github.com/cfwheels/cfwheels/issues/761) [Adam Chapman]

### Controller Enhancements

- Support for HTTP verbs, scopes, namespaces, and resources in routes (ColdRoute) [Don Humphreys, James Gibson, Tom King]
- Support for passing in `ram://` resources to `sendFile()` - [#566](https://github.com/cfwheels/cfwheels/issues/566) [Tom King]
- Extended `sendMail()` so that it can return the text and/or html content of the email - [#122](https://github.com/cfwheels/cfwheels/issues/122) [Adam Chapman]
- `renderWith()` can now set http status codes in header with the `status` argument - [#549](https://github.com/cfwheels/cfwheels/issues/549) [Tom King]
- Cross-Site Request Forgery (CSRF) protection - [#613](https://github.com/cfwheels/cfwheels/issues/613) [Chris Peters]
- Parse JSON body and add to params struct - [Tom King, Per Djurner]

### Bug Fixes

- Fixes skipped model instantiation due to Linux file case sensitivity - [#643](https://github.com/cfwheels/cfwheels/issues/643) [Adam Chapman, Tom King]
- Avoid double redirect error when doing delayed redirects from a verification handler function - [Per Djurner]
- Fixes attempts to insert nulls for blank strings - [#654](https://github.com/cfwheels/cfwheels/issues/654) [Andy Bellenie, Per Djurner]
- Fix for using `validatePresenceOf()` with default on update - [Andy Bellenie]
- Fixes so paginated finder calls with no records include column names - [#722](https://github.com/cfwheels/cfwheels/issues/722) [Per Djurner]
- Fixes "invalid data" error when using unsigned integers in MySQL - [#768](https://github.com/cfwheels/cfwheels/issues/768) [Per Djurner]

### Plugins

- Plugins now distributed via forgebox.io [Tom King]
- Update to the plugin system to allow overriding of the same framework method multiple times - [#681](https://github.com/cfwheels/cfwheels/issues/681) [James Gibson, Tom King]
- Added ability to turn off incompatible plugin warnings from showing - [Danny Beard]
- Plugins now have any java lib/class files automatically mapped onApplicationStart [731](https://github.com/cfwheels/cfwheels/issues/731) [Andy Bellenie, Tom King]
- Plugins now read version number off their `box.json` files and are displayed in debug area [#68](https://github.com/cfwheels/cfwheels/issues/68) [Tom King]
- Plugin meta data as set in `box.json` now available in `application.wheels.pluginMeta` scope [#68](https://github.com/cfwheels/cfwheels/issues/68) [Tom King]

### Miscellaneous

- Redirect away after a reload request - [Chris Peters]
- Support checking IP in `http_x_forwarded_for` when doing maintenance mode exclusions - [Per Djurner]
- Support checking user agent string when doing maintenance mode exclusions - [Per Djurner]
- Added JUnit and JSON format test results - [Adam Chapman]
- Added empty application test directories - [Chris Peters, Adam Chapman]
- Added `beforeAll()`, `afterAll()`, `packageSetup()`, `packageTeardown()` methods to test framework #651 - [Adam Chapman]
- Added `errorEmailFromAddress` and `errorEmailToAddress` config settings - [#95](https://github.com/cfwheels/cfwheels/issues/95) [Andy Bellenie, Tony Petruzzi, Per Djurner]
- Support for passing in any "truthy" value to `assert()` in tests - [Per Djurner]
- Added `/app/` mapping pointing to the root of the application - [Per Djurner]
- Added a `processRequest()` function that simplifies testing controllers - [Per Djurner]
- Added new embedded documentation viewer/generator for JavaDoc - [#734](https://github.com/cfwheels/cfwheels/issues/734) [Tom King]
- Removes all references to Railo - [#656](https://github.com/cfwheels/cfwheels/issues/656) (Adam Chapman)
- Made uncountable and irregular words configurable - [#739](https://github.com/cfwheels/cfwheels/issues/739) [Per Djurner]
- Removed `design` mode - [Per Djurner]
- Removed `cacheRoutes` setting - [Per Djurner]
- The `cacheFileChecking` and `cacheImages` settings are now turned off in development mode - [Per Djurner]
- Added `includeErrorInEmailSubject` setting - [Per Djurner]
- Environment switching via URL can now be turned off via `allowEnvironmentSwitchViaUrl` - [#766](https://github.com/cfwheels/cfwheels/issues/766) [Tom King]

### Breaking Changes

- Minimum Lucee version is now 4.5.5.006.
- Minimum ACF version is now 10.0.23 / 11.0.12.
- Support for Railo has been dropped.
- Rewrite and config files for IIS and Apache have been removed and has to be added manually instead.
- The `events/functions.cfm` file has been moved to `global/functions.cfm`.
- The `models/Model.cfc` file should extend `wheels.Model` instead of `Wheels` (`models/Wheels.cfc` can be deleted).
- The `controllers/Controller.cfc` file should extend `wheels.Controller` instead of `Wheels` (`controllers/Wheels.cfc` can be deleted).
- The `init` function of controllers and models should now be named `config` instead.
- The global setting `modelRequireInit` has been renamed to `modelRequireConfig`.
- The global setting `cacheControllerInitialization` has been renamed to `cacheControllerConfig`.
- The global setting `cacheModelInitialization` has been renamed to `cacheModelConfig`.
- The global setting `clearServerCache` has been renamed to `clearTemplateCache`.
- The `updateProperties()` method has been removed, use `update()` instead.
- Form labels automatically generated based on foreign key properties will drop the "Id" from the end (e.g., the label for the "userId" property will be "User", not "User Id").
- Routes need to be updated to use the new routing system by calling `mapper()`.
- JavaScript arguments like `confirm` and `disable` have been removed from the link and form helper functions (use the [JS Confirm](https://github.com/perdjurner/cfwheels-js-confirm) and [JS Disable](https://github.com/perdjurner/cfwheels-js-disable) plugins to reinstate the old behaviour).
- Timestamping (`createdAt`, `updatedAt`) is now in UTC by default (set the global `timeStampMode` setting to `local` to reinstate the old behaviour).
- Blank strings in SQL are now converted to null checks (e.g. `where="x=''"` becomes `where="x IS NULL"`).
- Tags are now closed in HTML5 style (e.g. `<img src="x">` instead of `<img src="x" />`).
- The `encode` argument to `mailTo` now encodes tag content and attributes instead of outputting JavaScript.
- Class output is now dasherized (e.g. `field-with-errors` instead of `fieldWithErrors`).
- The `renderPage` function has been renamed to `renderView`.
- `dbmigrate` is now named `Migrator`
- Automatic database migrations are disabled by default. Use `autoMigrateDatabase` setting to enable.
- Migrator does not write .sql files by default. Use `writeMigratorSQLFiles` to enable
- Migrator does not allow 'down' migrations outside of the 'development' environment by default. Use `allowMigrationDown` to enable.

----

<a name="1.4.6"></a>

## [1.4.6](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.6) => 2017.10.01

### Bug Fixes

- Made humanize() keep spaces in input - #663 [Per Djurner, Chris Peters]
- Added spatial datatypes for MySQL - #660 [Norman Cesar]
- Scope variable to avoid object being returned as NULL - #783 [Adam Larsen, Dmitry Yakhnov]
- Include "MariaDB" in database check connection string - #563 [Adam Chapman]
- Fixes MySQL attempts to insert nulls for blank strings - #680 [Andy Bellenie]

----

<a name="1.4.5"></a>

## [1.4.5](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.5) => 2016.03.30

### Bug Fixes

- Display URL correctly in error email when on HTTPS - [Per Djurner]
- Added the `datetimeoffset` data type to the Microsoft SQL Server adapter - [Danny Beard]
- Fix for test link display in debug footer - [#588](https://github.com/cfwheels/cfwheels/issues/588) [Tom King]
- Don't include query string when looking for image on file through `imageTag()` - [Per Djurner]
- Format numbers in `paginationLinks()` - [Per Djurner]
- Correct plugin filename case on application startup - [#586](https://github.com/cfwheels/cfwheels/issues/586) [Chris Peters]
- Clear out cached queries on reload - [#585](https://github.com/cfwheels/cfwheels/issues/585) [Andy Bellenie]

----

<a name="1.4.4"></a>

## [1.4.4](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.4) => 2015.02.10

### Bug Fixes

- Check global "cacheActions" setting - [#572](https://github.com/cfwheels/cfwheels/issues/572) [Andy Bellenie, Per Djurner]
- Fixed parsing for SQL IN parameters - [#564](https://github.com/cfwheels/cfwheels/issues/564) [Lee Bartelme, Per Djurner]
- Pass through all arguments properly when using findOrCreateBy - [#561](https://github.com/cfwheels/cfwheels/issues/561) [Per Djurner]
- Make it possible to disable session management on a per request basis - [#493](https://github.com/cfwheels/cfwheels/issues/493) [Andy Bellenie, Per Djurner]
- Allow mailParams to be passed through to sendEmail() - [#565](https://github.com/cfwheels/cfwheels/issues/565) [Tom King]
- Fixed inconsistency in form helpers for nested properties - [Marc Funaro, Per Djurner, Chris Peters]
- Fixed issue with grouping on associated models - [Song Lin, Per Djurner]
- Made the pagination() function available globally - [#560](https://github.com/cfwheels/cfwheels/issues/560) [Chris Peters, Per Djurner]

----

<a name="1.4.3"></a>

## [1.4.3](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.3) => 2015.10.16

### Bug Fixes

- Fix for using cfscript operators in condition and unless arguments - [Per Djurner]
- Added try / catch on getting host name since CreateObject("java") can be unavailable for security reasons - [Per Djurner]
- Fixed bug with cache keys always changing even though the input was the same - [Per Djurner]
- Remove white space character in output - [Bill Tindal, Per Djurner]
- Use correct path info in error email and debug area - [Per Djurner]
- Fixed plugin injection issue on start-up - [#556](https://github.com/cfwheels/cfwheels/issues/556) [Adam Chapman, Per Djurner]
- Skip calculated properties that are aggregate SQL functions in the GROUP BY clause - [#554](https://github.com/cfwheels/cfwheels/issues/554) [Adam Chapman, Per Djurner]
- Fixed error when trying to validate uniqueness on blank numeric properties - [#558](https://github.com/cfwheels/cfwheels/issues/558) [Chris Peters, Per Djurner]

----

<a name="1.4.2"></a>

## [1.4.2](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.2) => 2015.08.31

### Bug Fixes

- Fix for selecting distinct with calculated property - [Edward Chanter, Per Djurner]
- Fixed so default values are applied to non persistent properties - [#519](https://github.com/cfwheels/cfwheels/issues/519) [Andy Bellenie]
- Fixed missing var scope causing error on Lucee - [Russ Michaels, Tom King]
- Don't show debug info on AJAX requests - [#496](https://github.com/cfwheels/cfwheels/issues/496) [Leroy Mah, Per Djurner]
- Fixed permissions issue with imageTag() when running on shared hosting - [Per Djurner]
- Removed use of ExpandPath() in debug file since it was causing file permission issues - [Peter Hopman, Per Djurner]
- Skip setting object property when NULL is passed in - [#507](https://github.com/cfwheels/cfwheels/issues/507) [Andy Bellenie, Per Djurner]
- Fixed edge case issue with calling dynamic association methods - [#501](https://github.com/cfwheels/cfwheels/issues/501) [Dominik Hofer, Per Djurner]
- Fixed lock name in onSessionEnd event - [#499](https://github.com/cfwheels/cfwheels/issues/499) [Per Djurner]
- Ignore white space in the "where" argument to finders - [#503](https://github.com/cfwheels/cfwheels/issues/503) [Per Djurner]
- Ignore spaces in the "keys" argument to hasManyCheckBox() and hasManyRadioButton() - [Song Lin, Per Djurner]
- Skip running callbacks when validating uniqueness and similar situations - [#492](https://github.com/cfwheels/cfwheels/issues/492) [Andy Bellenie, Per Djurner]
- Avoid plugin directory exception during first application load - [#541](https://github.com/cfwheels/cfwheels/issues/541) [Adam Chapman, Per Djurner]
- Fix for using cfscript operators in "condition" and "unless" argument on ACF 8 - [#531](https://github.com/cfwheels/cfwheels/issues/531) [Per Djurner]
- afterSave and afterCreate callbacks are not firing on nested objects - [#525](https://github.com/cfwheels/cfwheels/issues/525) [Adam Chapman, Chris Peters, Per Djurner]
- Fix for rolling back nested properties - [#539](https://github.com/cfwheels/cfwheels/issues/539) [James Gibson, Chris Peters, Per Djurner]
- Ability to pass in list to "includeBlank" argument on dateSelect() and similar functions - [#502](https://github.com/cfwheels/cfwheels/issues/502) [Thorsten Eilers, Per Djurner]
- Ability to set attributes on the input element created by buttonTo() - [Per Djurner]
- Added missing "onlyPath" argument to imageTag() - [#508](https://github.com/cfwheels/cfwheels/issues/508) [Per Djurner]
- Corrected output of property labels in error messages - [#494](https://github.com/cfwheels/cfwheels/issues/494) [Andy Bellenie]

----

<a name="1.4.1"></a>

## [1.4.1](https://github.com/cfwheels/cfwheels/releases/tag/v1.4.1) => 2015.05.30

### Bug Fixes

- Skip callbacks when running calculation methods - [#488](https://github.com/cfwheels/cfwheels/issues/488) [Adam Chapman, Per Djurner]
- Fixed rewrite rules so base URL is rewritten correctly on Apache - [#367](https://github.com/cfwheels/cfwheels/issues/367) [Jeremy Keczan, Per Djurner]
- Removed incorrect path info information set by Apache - [#367](https://github.com/cfwheels/cfwheels/issues/367) [David Belanger, Per Djurner]
- Fixed routing bug when running from a sub folder on Adobe ColdFusion 10 - [Brant Nielsen, Per Djurner]
- Made sure error emails never depend on application variables being set - [Per Djurner]
- Fix for using cfscript operators in "condition" and "unless" argument on ACF 8 - [Per Djurner]

### Miscellaneous

- Removed tests folder - [Per Djurner]
- Updates to framework utility pages - Update logo, Fix links on congrats page to point to new documentation site - [Chris Peters]

----

<a name="1.4"></a>

# [1.4](https://github.com/cfwheels/cfwheels/releases/tag/v1.4) => 2015.05.08

### Model Enhancements

- Allow spaces in list passed in to the "include" argument on finders - [#150](https://github.com/cfwheels/cfwheels/issues/150) [Per Djurner]
- Added findOrCreateBy[Property](), findAllKeys(), findFirst() and findLast() finder methods - [Per Djurner]
- Add support for "GROUP BY" in sum(), average() etc. - [#464](https://github.com/cfwheels/cfwheels/issues/464) [Per Djurner]
- Made exists() check for any record when "key" and "where" is not passed in [Per Djurner]
- Added clearChangeInformation() for clearing knowledge of object changes - [#433](https://github.com/cfwheels/cfwheels/issues/433) [Jeremy Keczan, Per Djurner]
- Evaluate validation error messages at runtime - [#470](https://github.com/cfwheels/cfwheels/issues/470) [Per Djurner]

### View Enhancements

- Respect blank "text" argument in linkTo() - [#365](https://github.com/cfwheels/cfwheels/issues/365) [Adam Chapman, Tony Petruzzi, Per Djurner]
- Allow styleSheetLinkTag() and JavaScriptIncludeTag() to reference files starting from the root - [Per Djurner]
- Added "monthNames" and "monthAbbreviations" arguments to form helpers for easy localization - [Per Djurner]

### Controller Enhancements

- Ability to prepend functions to the filter chain instead of appending - [#321](https://github.com/cfwheels/cfwheels/issues/321) [Per Djurner]
- Pass in "appendToKey" to caches() to cache content separately - [#439](https://github.com/cfwheels/cfwheels/issues/439) [Per Djurner]
- Allow external attachments with sendEmail() - [Adam Chapman, Tony Petruzzi]
- Ability to redirect to a specific URL - [Simon Allard]
- Option to correct JSON output by passing in x="string" or x="integer" to renderWith() - [Per Djurner]

### Bug Fixes

- Fix for blank path_info in CGI scope - [#447](https://github.com/cfwheels/cfwheels/issues/447) [Tim Badolato, Tony Petruzzi, Per Djurner]
- Fix for accessing request scope key that does not exist from session - [#446](https://github.com/cfwheels/cfwheels/issues/446) [Brent Alexander, Per Djurner]
- Removed "validate" property that was incorrectly set when calling create() - [Per Djurner]
- Pass through "parameterize" in exists() [Per Djurner]
- Do not remove "AS" when it's in the SQL for a calculated property - [#453](https://github.com/cfwheels/cfwheels/issues/453) [Jean Duteau, Per Djurner]
- Obfuscate parameters in named route patterns when URL rewriting is off - [#455](https://github.com/cfwheels/cfwheels/issues/455) [Amber Cline, Per Djurner]
- Pass through "includeSoftDeletes" argument correctly - [#451](https://github.com/cfwheels/cfwheels/issues/451) [Jon Brose]

### Miscellaneous

- Support for the Lucee server - [Tom King]
- Made "development" the default environment mode - [Per Djurner]
- Removed deprecation work-around for the "if" argument on validation helpers - [Per Djurner]
- Removed deprecation work-around for the "class" argument on association initialization methods - [Per Djurner]
- Removed the "lib" folder - [Per Djurner]
- Removed the h() function, use XMLFormat() instead - [Per Djurner]

----

<a name="1.3.4"></a>

## [1.3.4](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.4) => 2015.02.30

### Miscellaneous

- Removed unnecessary tests folder [Brant Nielsen, Per Djurner]

----

<a name="1.3.3"></a>

## [1.3.3](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.3) => 2015.02.02

### Bug Fixes

- Correct output of boolean HTML attributes using new global "booleanAttributes" setting - [#377](https://github.com/cfwheels/cfwheels/issues/377) [James Hayes, Per Djurner]
- Make sure locks cannot be affected by other applications running on the same server - [Jonathan Smith, Per Djurner]
- Fixed bug with updating an integer column from NULL to 0 - [#436](https://github.com/cfwheels/cfwheels/issues/436) [Simon Allard, Per Djurner]
- Fixed potential permissions issue when running on shared hosting - [John Bliss, Per Djurner]

----

<a name="1.3.2"></a>

## [1.3.2](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.2) => 2014.11.11

### Bug Fixes

- Fixed regression bug with setting unique id for nested properties - [Simon Allard, Per Djurner]
- Fixed reversed usage for setting option text / value when passing in an array of structs to select() / selectTag() - [Per Djurner]
- Tableless models should not require dataSourceName - [#351](https://github.com/cfwheels/cfwheels/issues/351) [Jeremy Keczan, Singgih Cahyono]
- Fixed issue with using group by with calculated properties - [#89](https://github.com/cfwheels/cfwheels/issues/89) [Adam Chapman, Per Djurner, Singgih Cahyono]
- Fixed ORM incorrectly parsing a property value as NULL - [#209](https://github.com/cfwheels/cfwheels/issues/209) [Chris Peters, Per Djurner]
- Fixed bug with application scope when sharing name across applications - [#359](https://github.com/cfwheels/cfwheels/issues/359) [Singgih Cahyono]
- Fix for removing "AS" from ORDER BY clause in Microsoft SQL Server - [#132](https://github.com/cfwheels/cfwheels/issues/132) [Troy Murray, Tony Petruzzi, Charley Contreras, Per Djurner]
- Calling valid() will now correctly validate all associations when using nested properties - [#284](https://github.com/cfwheels/cfwheels/issues/284) [Adam Chapman, Per Djurner]
- Fixed issue with save() causing callbacks to run twice when using nested properties - [#284](https://github.com/cfwheels/cfwheels/issues/284) [Adam Chapman, Per Djurner]
- Fixed race condition issue with caching - [#376](https://github.com/cfwheels/cfwheels/issues/376) [Brian Parks, Tom King, Per Djurner]
- Fixed number parsing in WHERE strings - [Per Djurner]

----

<a name="1.3.1"></a>

## [1.3.1](https://github.com/cfwheels/cfwheels/releases/tag/v1.3.1) => 2014.08.25

### Bug Fixes

- Fixed issue with calling addFormat() on application start-up - [#333](https://github.com/cfwheels/cfwheels/issues/333) [Tom King, Per Djurner]
- Fixed so that Railo outputs ids for nested properties as integers instead of exponents - [Jordan Clark]
- Make sure that ids for nested properties are unique - [Sam Hakimi, Tony Petruzzi]
- Allow models to be created with no properties - [Tony Petruzzi, Singgih Cahyono]
- Added missing "prepend" and "append" arguments on startFormTag() and endFormTag() - [Per Djurner]
- Fix for fetching inserted primary key value from an Oracle database when using Adobe ColdFusion - [Per Djurner]
- When using autoLink(), make sure that links beginning with "www" have a protocol - [Benjamin Melançon, Tony Petruzzi]
- Plugin folder name should be lower case as per convention - [#320](https://github.com/cfwheels/cfwheels/issues/320) [Singgih Cahyono]
- Clear statically cached pages on reload - [Per Djurner]
- Do not run filters and verifications when caching actions statically - [Per Djurner]
- Fixed a bug where trying to obfuscate a high number was throwing an error - [Per Djurner]
- Fixed bug with static caching on Adobe ColdFusion 9 - [#332](https://github.com/cfwheels/cfwheels/issues/332) [Charley Contreras]
- Allow for format auto-detection when HTTP ACCEPT contains multiple values - [#297](https://github.com/cfwheels/cfwheels/issues/297) [Raul Riera, Singgih Cahyono]
- Fixed so that sendEmail() can use the "remove" attribute to delete attachments - [#339](https://github.com/cfwheels/cfwheels/issues/339) [Simon Allard]
- Fixed bugs with using the "twelveHour" argument on form helpers - [#342](https://github.com/cfwheels/cfwheels/issues/342), #343 [Jeremy Keczan, Per Djurner]
- Fixed issue with using non-ascii characters in routes - [#138](https://github.com/cfwheels/cfwheels/issues/138) [Chris Ogden, Singgih Cahyono, Per Djurner]

----

# [1.3] => 2014.08.05

### Model Enhancements

- Support for tableless models - [Tony Petruzzi]
- Alias table names using the association name in the "FROM" clause of a query when needed - [James Gibson, Per Djurner]
- New global "modelRequireInit" setting that you can set to "true" to require an init function specified in all models - [Jonathan Smith]
- Place surrounding parentheses on calculated properties in "where" and "order by" clauses - [Andy Bellenie, Per Djurner]
- Check to see if a given primary key already exists before adding it through setPrimaryKey() - [Mark Moran]

### View Enhancements

- Made it possible to set global defaults on autoLink(), excerpt(), wordTruncate() and simpleFormat() - [Chris Peters]
- Added server host name to debug info and error email - [Colin MacAllister]
- Made it possible to set a global default for the "twelveHour" argument on date / time helpers - [Per Djurner]
- Added "prepend / "append" arguments on buttonTag() - [Per Djurner]
- New "aroundRight" option on the "labelPlacement" argument that places the label text to the right of the form input - [Adam Chapman, Per Djurner]
- Support for HTML5 "type" argument in form field helpers - [Per Djurner]
- Support for HTML5 boolean attributes - [Per Djurner]
- Ability to remove media / type attributes when using styleSheetLinkTag and JavaScriptIncludeTag - [Per Djurner]
- Support for implicit protocol in JavaScriptIncludeTag and styleSheetLinkTag - [Per Djurner]
- Setting to convert, for example, dataDomCache or data_dom_cache (default) view helper argument names to data-dom-cache attribute names - [Per Djurner]
- Allow the class attribute for paginationLinks helper anchor tags - [Adam Chapman]

### Controller Enhancements

- Added the ability to pass through arguments from the view to the data Function in the controller - [Per Djurner]
- Made setPagination() available from the controller layer - [Per Djurner]

### Bug Fixes

- Fixed issue with double camel-casing of already singular strings [Don Humphreys]
- Fixes issue with running CFWheels with strict scope cascading enabled in Railo - [Jason Weible]
- Prevent stack overflow error with named arguments on dynamic update - [Tony Petruzzi]
- Fixes pagination bug when using association methods with a blank "where" clause - [Andy Bellenie]
- Added missing "validate" argument to create() - [Andy Bellenie]
- Fixed issue with deleting plugins on case sensitive systems - [Mark Moran]
- Make sure the latest version of a plugin is unpacked if multiple versions exists - [Tony Petruzzi]
- Fixed so the "onApplicationEnd" and "onSessionEnd" events pass through the arguments scope [Per Djurner]
- Fixed so the "onSessionEnd" event fires correctly - [#172](https://github.com/cfwheels/cfwheels/issues/172) [Per Djurner]
- Added geometry and geography datatypes (SQLServer) - [Simon Allard]
- Allow blank values to be passed through when validating uniqueness - [Per Djurner]
- Added work-around for "FastHashRemoved" struct bug found in ColdFusion 8 - [Per Djurner]
- Removed old bug fix to make redirectTo() respect anchors - [Per Djurner]
- Correct controller action caching - [#153](https://github.com/cfwheels/cfwheels/issues/153) [Tobias Reiter, Per Djurner]
- Fix for creating objects from the root folder on Railo 4 - [Jordan Clark, Adam Chapman]
- Fix for detecting that Microsoft SQL Server is used - [Tony Petruzzi, Adam Chapman]
- Don't assume null is false for boolean properties - [Adam Chapman]
- Allow to pass in encoded versions of "&"" and "=" (%26 and %3D) to the params argument - [#173](https://github.com/cfwheels/cfwheels/issues/173) [Mark Gaulin, Per Djurner]
- Avoid error when the first request to the app is an invalid one - [#222](https://github.com/cfwheels/cfwheels/issues/222) [Maxime de Visscher, Per Djurner]
- Get the error location from the correct exception struct - [#223](https://github.com/cfwheels/cfwheels/issues/223) [Adam Chapman, Per Djurner]
- Do not trim primary key values - [#213](https://github.com/cfwheels/cfwheels/issues/213) [Jeremy Keczan, Per Djurner]
- Incorrect pagination query with Oracle - [#93](https://github.com/cfwheels/cfwheels/issues/93) [crsedgar, Tony Petruzzi, Singgih Cahyono]
- Repair Oracle test failures #187 (Tony Petruzzi, Singgih Cahyono)
- Plugins with global mixin are ignored in unit tests - [Singgih Cahyono, Tony Petruzzi]
- Automatic validation should validate primary key - [#143](https://github.com/cfwheels/cfwheels/issues/143) [Adam Chapman, Tony Petruzzi]

### Miscellaneous

- Made application start-up thread safe - [Per Djurner]
- Performance improvement for locking - [Per Djurner]
- Case insensitive loading of controllers and models - [Per Djurner]
- Browse test packages for core, app and plugins - [Adam Chapman, Tony Petruzzi]
- Refactored to avoid a Duplicate() call when sending error email - [Per Djurner]

----

## [1.1.8] => 2012.05.21

### Model Enhancements

- Add boolean type to validatesFormatOf() - [Andy Bellenie]

### View Enhancements

- Add delimiter parameter to the highlight() function - [#826](https://github.com/cfwheels/cfwheels/issues/826) [Per Djurner, Tony Petruzzi]
- Use mark tag in highlight - [#836](https://github.com/cfwheels/cfwheels/issues/836) [Per Djurner, Tony Petruzzi]
- Add parameters append and prepend to the submitTag() - [#593](https://github.com/cfwheels/cfwheels/issues/593) [Per Djurner, Tony Petruzzi]

### Bug Fixes

- Turned off URL rewriting in IIS 7 by default - [Per Djurner, Tony Petruzzi]
- Add CFFileServlet to the pattern list, of the rewrite rules file, to be able to display an image when using <cfimage action='writeToBrowser'> - [ellor1138]
- radioButtonTag() checked attribute is ignored if value attribute is empty - [#733](https://github.com/cfwheels/cfwheels/issues/733) [Per Djurner, Tony Petruzzi]
- make cached queries respect the 'maxrows' argument (findAll) - [#824](https://github.com/cfwheels/cfwheels/issues/824) [Per Djurner, Tony Petruzzi]

### Miscellaneous

- Update web.config, htaccess to ignore favicon.ico - [Cathy Shapiro, Tony Petruzzi]
- Route with only format specified was throwing error - [jjallen, Tony Petruzzi]

----

## [1.1.7] => 12/11/2011.12.11

### Bug Fixes

- Filter controller and action params - [Pete Freitag, Andy Bellenie, Tony Petruzzi]

----

## [1.1.6] => 2011.10.08

### Model Enhancements

- validatesUniquenessOf only selects primary keys - [Jordan Clark, Don Humphreys]

### View Enhancements

- Allow removal height and/or width attributes from imageTag when set to false - [downtroden, Tony Petruzzi]
- Allow delimiter to be specified for stylesheets and javascripts - [Derek, Tony Petruzzi]

### Bug Fixes

- hasChanged was incorrectly evaluating boolean values - [Jordan Clark, Don Humphreys]
- Do not perform update when no changes have been made to the properties of a model - [#786](https://github.com/cfwheels/cfwheels/issues/786) [Mohamad El-Husseini, Tony Petruzzi]
- OnlyPath argument of urlFor does not correctly recognise HTTPS urls - [Andy Bellenie, Tony Petruzzi]
- Pagination clause wasn't enclosed - [Karl Deterville, Tony Petruzzi]
- Pagination endrow was incorrectly calculated - [Karl Deterville, Tony Petruzzi]

----

## [1.1.5] => 2011.08.01

### View Enhancements

- Escape html entities in text and value of select options - [#767](https://github.com/cfwheels/cfwheels/issues/767) [Richard Herbert, Tony Petruzzi]

### Bug Fixes

- Fix plugins not loading when application is in a subdirectory - [Mike Craig, Tony Petruzzi]

----

## [1.1.4] => 2011.07.20

### Model Enhancements

- Update to belongsTo(), hasOne() and hasMany() for the new argument joinKey. - [James Gibson, Tony Petruzzi]
- You can pass an unlimited number properties when using dynamic finders - [Tony Petruzzi]
- Dynamic finders now support passing in an array for values - [Tony Petruzzi]
- Added the delimiter argument to dynamic finders, this allow you to change the delimiter - [Tony Petruzzi]
- Added validationTypeForProperty() method - [Tony Petruzzi]

### View Enhancements

- Allow an array of structs to used for options in selectTag() - [Adam Chapman, Tony Petruzzi]
- Added secondStep parameter to date/time select tags - [Tom King, Tony Petruzzi]

### Bug Fixes

- Incorrect MIME type for JSON - [#751](https://github.com/cfwheels/cfwheels/issues/751) [daniel.mcq, Tony Petruzzi]
- Route with format will cause exception when route is selected and format is not provided - [#738](https://github.com/cfwheels/cfwheels/issues/738) [Danny Beard, Tony Petruzzi]
- Raise renderError when template is not found for format - [#759](https://github.com/cfwheels/cfwheels/issues/759) [Mike Henke, Tony Petruzzi]
- LabelClass should split up the list of classes and attach one class for each label - [#757](https://github.com/cfwheels/cfwheels/issues/757) [Mohamad El-Husseini, Tony Petruzzi]
- Transactions would not close when used with the dependent argument of hasMany() - [#739](https://github.com/cfwheels/cfwheels/issues/739) [Andy Bellenie]
- Soft deletes do not work correctly with outer joins - [#762](https://github.com/cfwheels/cfwheels/issues/762) [Andy Bellenie]
- Better error message when supplying a query param of type string and omitting single quotes - [#763](https://github.com/cfwheels/cfwheels/issues/763) [Adam Chapman, Tony Petruzzi]
- Allow commas in dynamic finders - [#771](https://github.com/cfwheels/cfwheels/issues/771) [Joshua, Tony Petruzzi]
- AMPM select displaying twice - [#768](https://github.com/cfwheels/cfwheels/issues/768) [John Bliss, Tony Petruzzi]
- \$request argumentsCollection: should be argumentCollection - [#772](https://github.com/cfwheels/cfwheels/issues/772) [William Fisk, Tony Petruzzi]
- Pagination pull incorrect number of results with compounded keys - [#725](https://github.com/cfwheels/cfwheels/issues/725) [Jeff Greenhouse, Tony Petruzzi]
- Update hasChanged() to properly check floats - [Andy Bellenie, Tony Petruzzi]
- Date tags selected date throws out of range error - [Ben Garrett, Tony Petruzzi]

### Miscellaneous

- Added proper HTTP status headers - [#705](https://github.com/cfwheels/cfwheels/issues/705) [Randy Johnson , Andy Bellenie]
- Plugin development no longer requires a zip file. - [Tony Petruzzi]

----

## [1.1.3] => 2011.03.24

### Model Enhancements

- You can now have bracket markers for all validation arguments - [#706](https://github.com/cfwheels/cfwheels/issues/706) [Tony Petruzzi]
- Columns marked as not null should allow for blank strings - [Tony Petruzzi]

### View Enhancements

- Allows for relative url linking to be turned off in autolink() - [James Gibson, Tony Petruzzi]

### Controller Enhancements

- Allow for default argument on sendmail for from, to and subject - [#727](https://github.com/cfwheels/cfwheels/issues/727) [Andy Bellenie, Tony Petruzzi]

### Bug Fixes

- Fixed issue with $create supplying incorrect keys to $query - [Don Humphreys, Tony Petruzzi]
- The original transaction mode would not be respected during during callbacks - [Andy Bellenie, Tony Petruzzi]
- "none" transaction modes would never close - [Andy Bellenie, Tony Petruzzi]
- Incorrect \$cache argument - [#671](https://github.com/cfwheels/cfwheels/issues/671) [William Fisk, Tony Petruzzi]
- Route formats prevented fullstops from being used in params - [#666](https://github.com/cfwheels/cfwheels/issues/666) [Tom King, Raul Riera, Tony Petruzzi]
- Controller in params should be upper camel case - [#703](https://github.com/cfwheels/cfwheels/issues/703) [William Fisk, Tony Petruzzi]
- Application scope would not initialize in sub - [#721](https://github.com/cfwheels/cfwheels/issues/721) [Adam Chapman, Tony Petruzzi]
- ValidatesUniquenessOf doesn't read soft-deletes - [#719](https://github.com/cfwheels/cfwheels/issues/719) [Andy Bellenie, Tony Petruzzi]
- PaginationLinks(): routes with page number marker variable would produce the wrong links - [Kenneth Barrett, Tony Petruzzi]

----

## [1.1.2] => 2011.01.29

### Model Enhancements

- Add 'when' argument to validate() - [#643](https://github.com/cfwheels/cfwheels/issues/643) [Andy Bellenie, Tony Petruzzi]

### View Enhancements

- Select, SelectTag allow an array of structs to be passed to options - [#680](https://github.com/cfwheels/cfwheels/issues/680) [William Fisk, Tony Petruzzi]

### Controller Enhancements

- Changed "default" argument on includeContent() to "defaultValue" - [#663](https://github.com/cfwheels/cfwheels/issues/663) [Tony Petruzzi]

### Bug Fixes

- Added the varchar_ignorecase type to the H2 adapter - [#664](https://github.com/cfwheels/cfwheels/issues/664) [Per Djurner]
- Fix so that the full tablename is always returned - [#667](https://github.com/cfwheels/cfwheels/issues/667) [Tony Petruzzi]
- Pagaination with parameterize set to false for numeric keys - [#656](https://github.com/cfwheels/cfwheels/issues/656) [levi730, Tony Petruzzi]
- Blank should be the selected value when includeBlank is set - [#633](https://github.com/cfwheels/cfwheels/issues/633) [Tony Petruzzi]
- validatesLengthOf failed when both maximum and minimum were specified - [Tony Petruzzi]

----

## [1.1.1] => 2010.11.21

### Bug Fixes

- Added number formatting on the value passed in to "count" in the pluralize() function - [Per Djurner]
- Fixed renderWith() so that it works in all environment modes when returning JSON - [#644](https://github.com/cfwheels/cfwheels/issues/644) [Tony Petruzzi]
- Fixed belongsTo association code when using composite keys - [#641](https://github.com/cfwheels/cfwheels/issues/641) [James Gibson, Andy Bellenie]
- Allow cfthread to be used in views - [#612](https://github.com/cfwheels/cfwheels/issues/612) [Cathy Shapiro, Tony Petruzzi]
- Fixed paging code for non-parameterized queries - [#656](https://github.com/cfwheels/cfwheels/issues/656) [Mike Lester, Tony Petruzzi]
- Corrected bug in request verification when session management was disabled in Railo - [#658](https://github.com/cfwheels/cfwheels/issues/658) [Russ Sivak, Per Djurner]
- Changed "if" to "condition" on all validation methods to get around the fact that "if" is a reserved word in cfscript - [#660](https://github.com/cfwheels/cfwheels/issues/660) [Mohamad El-Husseini, Per Djurner]
- Fixed autolink() so that it correctly links and escapes relative paths - [#646](https://github.com/cfwheels/cfwheels/issues/646) [Tony Petruzzi]
- Fixed so including partials with layouts does not cause duplicated content - [#659](https://github.com/cfwheels/cfwheels/issues/659) [Per Djurner]

----

# [1.1] => 2010.11.19

### Bug Fixes

- Don't use the cfzip "overwrite" attribute when unzipping plugins since it updates the date on the files on Railo - [William Fisk, Per Djurner]
- Update to the error template to make sure errors are not thrown while trying to send out error emails - [James Gibson]
- Fixes a bug with obfuscation on Railo that happens when the mathematical constant "e" is in the string together with no other letters - [Jon Lynch, Tony Petruzzi, Per Djurner]
- Transaction="none" would throw an error if methods within a callback chain also attempted to make database changes - [#613](https://github.com/cfwheels/cfwheels/issues/613) [Andy Bellenie]
- Fixed bug that prevented the use of custom labels on calculated or non-persisted properties in form helpers and error messages - [#630](https://github.com/cfwheels/cfwheels/issues/630) [Andy Bellenie, Mike Henke]
- Update to renderwith() to return the content if "returnAs" equals "string" - [James Gibson, W. Scott Hayes]
- Removed case-sensitivity on labelXXX arguments passed through to form helpers - [Andy Bellenie]

----

# [1.1 RC 1] => 2010.10.27

### Bug Fixes

- The full tag context of an error was missing from the error emails, fixed now - [Andy Bellenie]
- Fixed bug in nested properties related to deleting children via object array - [#595](https://github.com/cfwheels/cfwheels/issues/595) [Adam Michel, Tony Petruzzi]
- Make sure transactions are rolled back and marker gets closed on error - [Tony Petruzzi]
- Fixed so deprecation notices only gets set when the debug info is to be displayed - [John C. Bland II, Per Djurner]
- Fix to make preserveSingleQuotes() call work in Railo 3.2 - [Raul Riera, Per Djurner]
- Fixed bug with dynamic finders where we were looking for a non existing data type on a calculated property - [Brian Ward, Per Djurner]
- Fix to make sure findOne() does not query the database for more records than needed - [#605](https://github.com/cfwheels/cfwheels/issues/605) [Per Djurner, Tony Petruzzi]
- Corrected H2, Oracle and PostgreSQL code for when GROUP BY clause needs to contain columns from the ORDER BY clause - [Per Djurner]
- Correction to get exactly one record when we're dealing with single associations instead of basing it on the "joinType" argument - [Per Djurner]
- Update to error handling to make sure the "rootCause" data exists before trying to use it - [James Gibson]
- Corrections and improvements to Oracle support - [Ryan Hoppitt, Tony Petruzzi, Per Djurner]
- Fixed so the "Message" part is also in lower case when "lowerCaseDynamicClassValues" is "true" in flashMessages() - [John C. Bland II, Per Djurner]
- Case corrections to ensure compatibility with Linux - [Per Djurner]
- Fix for using layouts on AJAX calls when usesLayout() has not been called - [Per Djurner]
- Added missing dependency operation remove with instantiation - [Andy Bellenie]
- Fixed bug with pagination and renamed primary keys - [Tony Petruzzi]

### Miscellaneous

- Added "errorClass" argument to form helpers and set the default to "fieldWithErrors" to make the naming consistent - [Per Djurner]

----

# [1.1 Beta 2] => 2010.10.05

### Bug Fixes

- Corrected some bugs related to case, ordering and pagination on the H2 database - [Per Djurner]
- made it possible to use plugins on the H2 database - [Per Djurner]
- Fixed autoLink() so that it can handle all types of domains - [#560](https://github.com/cfwheels/cfwheels/issues/560) [Tom King, Tony Petruzzi]
- Corrected deobfuscation logic so that it... umm... works :) - [#577](https://github.com/cfwheels/cfwheels/issues/577) [Per Djurner, James Gibson]
- Fix for obfuscateParam() related to leading zeros in integer values on Railo - [#578](https://github.com/cfwheels/cfwheels/issues/578) [Tony Petruzzi]
- Fixed so correct defaults are set for "valueField" and "textField" on select() when dealing with objects - [#445](https://github.com/cfwheels/cfwheels/issues/445) [Per Djurner]
- Adapters now only fall backs on native code for getting the last inserted key when Railo/ACF can't do it automatically - [#562](https://github.com/cfwheels/cfwheels/issues/562) [Per Djurner]
- simpleFormat() now produce the exact same output regardless of the operating system - [#570](https://github.com/cfwheels/cfwheels/issues/570) [Raul Riera, Tony Petruzzi, Per Djurner]
- imageTag() was outputting the "id" attribute twice when caching was on, fixed now - [#582](https://github.com/cfwheels/cfwheels/issues/582) [Andy Bellenie, Per Djurner]
- Changed to using SCOPE_IDENTITY() as fallback for SQL Server - [Tony Petruzzi, Per Djurner]
- Fixed overwrite problem when using composite keys - [#587](https://github.com/cfwheels/cfwheels/issues/587) [Andy Bellenie, Per Djurner]
- Fixed bug with upper case input in humanize() and allow exception list for when abbreviations aren't caught - [#587](https://github.com/cfwheels/cfwheels/issues/587) [Andy Bellenie, Tony Petruzzi, Per Djurner]
- Made it possible to call model (and other) methods on application / session start - [W. Scott Hayes, Per Djurner]
- Fixed bug in setPagination() where floats could be passed in for the numeric values - [Tony Petruzzi]
- Fixed so labels on dateTimeSelectTags() and dateTimeSelect() get applied correctly to all six possible form inputs - [#531](https://github.com/cfwheels/cfwheels/issues/531) [Raul Riera, Tony Petruzzi, Chris Peters, Per Djurner]
- Made it possible to call the controller data function from a partial located in the root or sub folder - [Per Djurner, Chris Peters]
- Fixed a PostgreSQL pagination query that would fail under certain conditions (edge case) - [Per Djurner]
- Fixed deleting in nested properties - [#579](https://github.com/cfwheels/cfwheels/issues/579) [Adam Michel, Tony Petruzzi]

### Miscellaneous

- Removed the `afterFindCallbackLegacySupport` setting and made the new way introduced in Beta 1 the only way - [#580](https://github.com/cfwheels/cfwheels/issues/580) [Per Djurner]
- Changed "class" attribute on flashMessages(), errorMessageOn() and errorMessagesFor() to be camelCased - [#554](https://github.com/cfwheels/cfwheels/issues/554) [Per Djurner]
- Added better error reporting when passing in one primary key value when multiple are expected - [#540](https://github.com/cfwheels/cfwheels/issues/540) [Adam Michel, Tony Petruzzi]

----

# [1.1 Beta 1] => 2010.09.10

### Model Enhancements

- Support for automatic validations based on database settings (column does not allow nulls, has a maximum length etc) - [James Gibson, Andy Bellenie, Tony Petruzzi]
- Support for handling binary data columns - [#133](https://github.com/cfwheels/cfwheels/issues/133) [Tony Petruzzi]
- Callbacks are not pre-loaded anymore - [#388](https://github.com/cfwheels/cfwheels/issues/388) [Andy Bellenie]
- Support for NOT IN, IN, NOT LIKE, IS NULL, IS NOT NULL in where clause with proper use of cfqueryparam - [Per Djurner, Tony Petruzzi]
- Made it possible to use a blank value as a property default - [Andy Bellenie]
- Ability to skip validation when saving, e.g. save(validate=false) - [Tony Petruzzi]
- Added argument for model methods to be able to turn off callbacks, e.g. save(callbacks=false) - [#236](https://github.com/cfwheels/cfwheels/issues/236) [Andy Bellenie]
- Ability to set a default value for column statistics with "ifNull" argument - [#330](https://github.com/cfwheels/cfwheels/issues/330) [Andy Bellenie]
- Support for nested properties (saving data in associated model objects through the parent) - [James Gibson]
- Added automatic deletion of dependent models - [#367](https://github.com/cfwheels/cfwheels/issues/367) (Per Djurner, Andy Bellenie]
- Added "setUpdatedAtOnCreate" to tell CFWheels if it should update the "updatedAt" property when creating new records - [James Gibson]
- New setting "useExpandedColumnAliases" that you can set to "true" to prepend included model properties with their model name in queries - [#442](https://github.com/cfwheels/cfwheels/issues/442) [Andy Bellenie]
- Arguments are now always passed in to "afterFind" callback methods and you can return them to set both queries and objects - [Tony Petruzzi]
- Updated findAll() to allow for more than one association as long as they are direct (i.e. include="assoc1,assoc2" works but not include="assoc1(assoc2)) - [James Gibson]
- Update to add GROUP BY functionality in finders - [James Gibson]
- Allow overriding of soft-deletes - [#324](https://github.com/cfwheels/cfwheels/issues/324) [Andy Bellenie]
- Added accessibleProperties() and protectedProperties() to protect model variables from mass assignment - [James Gibson]
- Ability to set defaults on a model using the "defaultValue" argument to property() - [#244](https://github.com/cfwheels/cfwheels/issues/244) [Andy Bellenie]
- Added transaction handling support, use the "transaction" argument on save(), updateAll() etc, callbacks are automatically wrapped in a transaction - [#325](https://github.com/cfwheels/cfwheels/issues/325) [Andy Bellenie]
- Added a position argument to primaryKeys() for easier retrieval - [Tony Petruzzi]
- Added a setPagination() function to make it possible to use paginationLinks() and similar functions for custom queries (i.e. ones not created with the CFWheels ORM) - [Tony Petruzzi]
- Allow database views to be used as a model by calling setPrimaryKey() - [#390](https://github.com/cfwheels/cfwheels/issues/390) [Tony Petruzzi]

### View Enhancements

- Labels will now be added automatically for form helpers based on the object's property name (or a custom label set in the model) - [Andy Bellenie]
- Added default for "action" argument on linkTo() - [#321](https://github.com/cfwheels/cfwheels/issues/321) [Andy Bellenie]
- Added 12-hour format to date/time select helpers - [#551](https://github.com/cfwheels/cfwheels/issues/551) [Tony Petruzzi]
- Added a flashMessages() function that outputs all key/values from the Flash - [Per Djurner]
- Added support for inherited / nested layout templates through includeLayout() - [Per Djurner]
- Added "head" argument to styleSheetLinkTag() and JavaScriptIncludeTag() - [Per Djurner]
- flashMessages() can now pass a list of keys that controls which messages to display as well as the order they are displayed in - [Chris Peters]
- Ability for years to display in descending order in date select form tags - [Tony Petruzzi]
- Support for an automatic "assetQueryString" which can be used to force local browser caches to refresh when there is an update to your assets (CSS, JavaScript etc) - [James Gibson]
- Added buttonTag() form helper - [Tony Petruzzi]
- Added "disabled" and "readonly" arguments to form input helpers [Andy Bellenie]
- Allows disabling error elements appearing on form fields by setting "errorElement" - [Andy Bellenie]
- Updates to checkBoxTag() and checkBox() to allow for unchecked values - [James Gibson]
- Added "pageNumberAsParam" argument to paginationLinks() that decides whether the page parameter should be part of the route or just a regular parameter - [James Gibson]
- Added contentFor() and includeContent() used to set/display content - [Tony Petruzzi, Per Djurner]
- Added hasManyRadioButton() and hasManyCheckBox() used to easily add radio buttons / checkboxes for a hasMany relationship on a model when using nested properties. - [James Gibson]
- New global defaults for truncate() and wordTruncate() - [James Gibson]
- Added a toXHTML() function that returns an XHTML compliant string - [Tony Petruzzi]
- Added "dataFunction" argument to includePartial() for getting data from a controller function automatically - [Per Djurner]
- Added a h() function for sanitizing user output - [Tony Petruzzi]
- Added support for external links in linkTo(), startFormTag(), javaScriptIncludeTag() and styleSheetLinkTag() - [Tony Petruzzi]

### Controller Enhancements

- Updated the request processing to not call the action if a before filter has rendered content - [James Gibson]
- Support for using an onMissingMethod() inside controllers - [James Gibson]
- redirectTo() now accepts a "delay" argument which can be used to delay the redirection until after the action code has completed (useful for testing) - [James Gibson, Tony Petruzzi]
- Added addDefaultRoutes(), used to control exactly where in the route order to place the default routes - [Per Djurner]
- New setting called "loadDefaultRoutes" which you can set to false when you want to use addDefaultRoutes() to load the routes manually - [Per Djurner]
- Added the ability to attach files with sendEmail() - [Per Djurner]
- Added "directory" and "deleteFile" arguments to sendFile() - [#323](https://github.com/cfwheels/cfwheels/issues/323) [Tony Petruzzi]
- Added the ability to set wildcard routes - [Andy Bellenie]
- Controllers can now respond to different formats such as "xml", "json", "csv", "pdf" and "xls" - [James Gibson]
- Ability to store Flash in cookies - [Per Djurner]
- Ability to add Flash messages when redirecting - [Per Djurner]
- redirecTo(back=true) can now fall back on a route/controller/action when the referrer is blank instead of throwing an error - [Per Djurner]
- Support for "format" parsing in route patterns ([controller]/[action].[format]) - [James Gibson]
- Ability to pass through arguments to filters - [Per Djurner]
- Added flashKeep() function for keeping Flash contents for one additional request - [Per Djurner]
- You can now validate type on incoming parameters using verifies() - [Tony Petruzzi]
- Defaulted day to 1 and month to 1 when submitting forms - [Tony Petruzzi]
- Added usesLayout() for specifying a controller specific layout - [Tony Petruzzi, Per Djurner]
- You can now perform a redirect instead of aborting the request using verifies(), any extra arguments passed in are passed through to redirectTo() - [Tony Petruzzi]

### Bug Fixes

- Session scope is now locked when accessing the Flash - [#275](https://github.com/cfwheels/cfwheels/issues/275) [James Gibson, Per Djurner]
- Corrected the "id" attribute for radioButton() when value is blank - [#373](https://github.com/cfwheels/cfwheels/issues/373) [Tony Petruzzi]
- findByKey() now correctly returns "false" when passed a blank "key" argument - [#514](https://github.com/cfwheels/cfwheels/issues/514) [Andy Bellenie]
- Fixed so hasChanged() compares dates correctly - [#515](https://github.com/cfwheels/cfwheels/issues/515) [Tony Petruzzi]
- validatesUniquenessOf() now recognizes soft-deleted columns as well - [#532](https://github.com/cfwheels/cfwheels/issues/532) [Andy Bellenie]
- Corrected a bad throw in onMissingMethod() - [#555](https://github.com/cfwheels/cfwheels/issues/555) [Per Djurner, Adam Michel]
- Corrected count() to always return 0 if no records are found - [Per Djurner]
- Removed differences in params structure for form / URL variables - [#232](https://github.com/cfwheels/cfwheels/issues/232) [Mike Henke, Tony Petruzzi]

### Miscellaneous

- Allowed plugins to run in maintenance mode - [James Gibson]
- Added "excludeFromErrorEmail" setting - [#447](https://github.com/cfwheels/cfwheels/issues/447) [Per Djurner]
- New setting, "errorEmailSubject", that allows you to customize the subject line of error emails - [#392](https://github.com/cfwheels/cfwheels/issues/392) [Per Djurner]
- New setting, "deletePluginDirectories" that tells CFWheels whether to delete plugin directories if no corresponding ZIP file exists - [#385](https://github.com/cfwheels/cfwheels/issues/385) [Per Djurner]
- Added a "cachePlugins" setting to allow developers to not cache plugins during the development of them - [#304](https://github.com/cfwheels/cfwheels/issues/304) [Andy Bellenie]
- Allow setting multiple argument defaults at once, e.g. set(functionName="textField,textArea,select", labelPlacement="before" - [#426](https://github.com/cfwheels/cfwheels/issues/426) [Raul Riera, Per Djurner]
- A full testing framework is now included in Wheels, unit tests can be created in the "tests" folder - [Tony Petruzzi]
- Adobe ColdFusion 8.0.1 or Railo 3.1.2.020 is now required [Tony Petruzzi, Per Djurner]
- Deprecated the "class" argument on association methods (belongsTo(), hasMany(), hasOne()), use "modelName" instead. - [Per Djurner]
- Refactor to avoid polluting the Application.cfc's this scope with the "rootDir" variable - [Per Djurner]

----

## [1.0.5] => 2010.06.18

### Bug Fixes

- Fixed the handling for the "errorEmailServer" setting so that error emails can now be sent without having to set the server in the ColdFusion administrator - [Per Djurner]
- Corrected pluralize rules - [#450](https://github.com/cfwheels/cfwheels/issues/450) [Joshua Clingenpeel, Tony Petruzzi]
- Remove possible spaces in list passed in to callback registration - [#448](https://github.com/cfwheels/cfwheels/issues/448) [Raul Riera]
- Check to see that a function has a declaration in the settings before setting defaults - [James Gibson]
- Update to capitalize() to return nothing if the passed in string is empty - [James Gibson]
- validatesPresenceOf() now takes whitespace into account - [Tony Petruzzi]
- Fix for lock timeouts occurring during race conditions in the "design" and "development" modes - [#467](https://github.com/cfwheels/cfwheels/issues/467) [John C. Bland II, Andy Bellenie, Tony Petruzzi]
- Fix so CFWheels uses passed in width/height in imageTag() when only one of them is passed in - [#328](https://github.com/cfwheels/cfwheels/issues/328) [Andy Bellenie, Per Djurner]
- Don't append .css, .js to asset files when they end in .cfm - [Tony Petruzzi]
- Update to reload to catch the query blank boolean error - [James Gibson]
- onCreate validations do not run when onSave validations fail - [#455](https://github.com/cfwheels/cfwheels/issues/455) [Andy Bellenie]
- Fixes bug with nullable foreign keys in where clause - [Andy Bellenie]
- Update to clean up variables from all scopes after running plugin injection - [James Gibson]
- Updated PostgreSQL types - [Jaroslaw Krzemienski, Per Djurner]
- Fix for race condition when checking for existing controller files in the "design" and "development" modes - [#360](https://github.com/cfwheels/cfwheels/issues/360) [Andrea Campolonghi, Per Djurner]
- Error in SQL Server pagination with mapped columns - [#456](https://github.com/cfwheels/cfwheels/issues/456) [Don Humphreys, Tony Petruzzi]
- Updated hasChanged() for a race condition that wasn't met - [James Gibson]
- Fixed pagination error in Oracle when using the "include" argument - [#449](https://github.com/cfwheels/cfwheels/issues/449) [Per Djurner]
- Fixed incorrect layout rendering for renderPartial() and includePartial() - [#488](https://github.com/cfwheels/cfwheels/issues/488) [Jordan Sitkin, Per Djurner]
- Fix for complex "include" strings - [#453](https://github.com/cfwheels/cfwheels/issues/453) [Jordan Sitkin, Andy Bellenie]
- Fixed naming conflict occurring for properties starting with the same name as its model on included objects - [#461](https://github.com/cfwheels/cfwheels/issues/461) [Tony Petruzzi, Per Djurner, Raul Riera]
- Fixed pluralization issue related to partials used with object(s)/queries and removed the limitation of the file being tied to the model name - [#427](https://github.com/cfwheels/cfwheels/issues/427) [Per Djurner, James Gibson]
- Prevent additional errors from occurring during display of CFML errors - [#466](https://github.com/cfwheels/cfwheels/issues/466) [John C. Bland II, Per Djurner, Tony Petruzzi]

----

## [1.0.4] => 2010.04.21

### Bug Fixes

- Added missing support for passing in array of model objects as options to select() - [#411](https://github.com/cfwheels/cfwheels/issues/411) [John C. Bland II, Tony Petruzzi]
- Fixed so "afterFind" callback methods are only called once during pagination - [#435](https://github.com/cfwheels/cfwheels/issues/435) [Bucky Schwarz, Doug Giles, Per Djurner]
- Added "prependOnAnchor" and "appendOnAnchor" arguments to paginationLinks() to get around an issue where the "appendToPage" string was added on anchor pages - [#434](https://github.com/cfwheels/cfwheels/issues/434) [Joshua Clingenpeel, Per Djurner]
- Fixed bug in paginationLinks() when using "appendToPage" with single page result - [Joshua Clingenpeel, Per Djurner]
- Fixed bug with count() when using composite primary keys - [Per Djurner]
- Fixed concurrency issue related to setting the model name on associations - [#419](https://github.com/cfwheels/cfwheels/issues/419) [John C. Bland II, Per Djurner]
- Fix for skipping duplicate columns returned from cfdbinfo when using Oracle - [#437](https://github.com/cfwheels/cfwheels/issues/437) & #439 [Mike Henke, Per Djurner]
- Fix for race conditions when setting the join clause in an application scoped model object - [#432](https://github.com/cfwheels/cfwheels/issues/432) [James Gibson, Per Djurner]
- Fixed so URLFor() is not duplicating controller and action when URL rewriting is off - [#433](https://github.com/cfwheels/cfwheels/issues/433) [Per Djurner]
- Added support to imageTag() for all image types that the CFML engine supports - [Cathy Shapiro, Per Djurner]

----

## [1.0.3] => 2010.03.26

### Bug Fixes

- Added support for more domains in autoLink() and also fixed linking when the URL starts at the very beginning of the string - [#424](https://github.com/cfwheels/cfwheels/issues/424) [Per Djurner]
- Corrected the order in which object properties are set when based on a query result - [#404](https://github.com/cfwheels/cfwheels/issues/404) & #422 [Raul Riera, Per Djurner]
- Fixed so the "appendToPage" and "prependToPage" arguments in paginationLinks() apply to the anchor pages - [#417](https://github.com/cfwheels/cfwheels/issues/417) [Raul Riera, Per Djurner]
- Changed so developer supplied arguments to URLFor() are not converted to lowercase - [#415](https://github.com/cfwheels/cfwheels/issues/415) [Per Djurner]
- Made sure you can only reload based on the URL when a reload password exists (either empty or set) - [#410](https://github.com/cfwheels/cfwheels/issues/410) [John C. Bland II, Per Djurner]
- Added escaping on strings used in JavaScript - [#393](https://github.com/cfwheels/cfwheels/issues/393) [Tony Petruzzi]
- Changed so the dispatch object is created with a reference from the root of the CFWheels application instead of the entire website - [Per Djurner]
- Fixed so sendEmail() automatically sets the "type" argument to "text" or "html" when only one template is in use - [Per Djurner]
- Fixed so creating SELECT clause works when there are 10 tables or more in use - [#421](https://github.com/cfwheels/cfwheels/issues/421) [Don Humphreys, Tony Petruzzi]
- Fixed a regression bug in the dateTimeSelect() function - [#413](https://github.com/cfwheels/cfwheels/issues/413) [Andy Bellenie]
- Fixed bug in dynamic belongsTo() methods - [#420](https://github.com/cfwheels/cfwheels/issues/420) [Andy Bellenie]
- Fixed error with a call to http://localhost/badtemplate.cfm not showing the output of the onmissingtemplate.cfm file - [Clarke Bishop, Andy Bellenie, Per Djurner]
- Corrected link in error email when URL rewriting is on - [Andy Bellenie]

----

## [1.0.2] => 2010.02.19

### Bug Fixes

- Added work-around for CF9 / OSX related "extends" bug in MySQL adapter - [#378](https://github.com/cfwheels/cfwheels/issues/378) [Russ Johnson, Jordan Sitkin, John C. Bland II, Per Djurner]
- Fixed call to non existing function in URLFor() - [Andy Bellenie, Per Djurner]

----

## [1.0.1] => 2010.02.16

### Bug Fixes

- Fixed bug in MS SQL adapter when paginating and ordering on identically named columns from two tables - [#355](https://github.com/cfwheels/cfwheels/issues/355) [Don Bellamy, Per Djurner]
- Fixed bug where soft deleted rows were returned when using the include argument - [#344](https://github.com/cfwheels/cfwheels/issues/344) [Andy Bellenie, Per Djurner]
- Fixed bug where humanize() would add a space at the beginning of the string if it started with an upper case character - [#359](https://github.com/cfwheels/cfwheels/issues/359) [Per Djurner]
- To fix bugs with change tracking CFWheels will now only check for changes to properties that exist on the model object - [#353](https://github.com/cfwheels/cfwheels/issues/353) [James Gibson, Per Djurner]
- Fixed so the keys we use for caching always return identical results so they do not break the cache unnecessarily - [Andy Bellenie, Per Djurner]
- Fixed so average() with integer values work in Railo - [#331](https://github.com/cfwheels/cfwheels/issues/331) [Raul Riera, James Gibson, Per Djurner]
- Fixed so the "for" attribute on form helpers always matches the "id" attribute when it's passed in by the developer - [#340](https://github.com/cfwheels/cfwheels/issues/340) [Chris Peters, Per Djurner]
- Fixed so findAll() afterFind callbacks run when one record is returned - [#327](https://github.com/cfwheels/cfwheels/issues/327) [Ryan Hoppitt, Per Djurner]
- Wrapped debug output completely in "cfoutput" tags so that it works when "enableCFOutputOnly" has been set to true - [William Fisk, Per Djurner]
- Fixed a bug with pagination with outer joins that was creating SQL errors when no records were returned from the pagination query - [James Gibson]
- Made the "objectName" argument check for the object in the "variables" scope by default instead of unscoped - [#365](https://github.com/cfwheels/cfwheels/issues/365) [John C. Bland II, Per Djurner]
- Fixed so the this.dataSource setting is picked up by CFWheels when used - [#333](https://github.com/cfwheels/cfwheels/issues/333) [Chris Peters, Per Djurner]
- Fixed so you can use the built-in validation methods for properties that does not exist in the database table - [#362](https://github.com/cfwheels/cfwheels/issues/362) [Andy Bellenie, Per Djurner]
- Fixed so primary key column is not added to order clause when paginating if it has already been specified with tableName.columnName syntax - [Per Djurner]
- Fixed so pluralization/singularization works with camelCased variable names - [Chris Peters, Per Djurner]
- Added line break to stylesheetLinkTag and javaScriptIncludeTag output - [#372](https://github.com/cfwheels/cfwheels/issues/372) [Tony Petruzzi]
- Fixed bug with select() and selectTag() failing with empty collections as options - [#374](https://github.com/cfwheels/cfwheels/issues/374) [Tony Petruzzi]
- Added missing option "variableName" to validatesFormatOf() options - [#337](https://github.com/cfwheels/cfwheels/issues/337) [Raul Riera, Per Djurner]
- Get disallowed methods from Wheels.cfc instead to allow methods in Controller.cfc to be executed as actions - [Per Djurner]
- Fixed so all callbacks run when the valid() method is called - [#303](https://github.com/cfwheels/cfwheels/issues/303) [Tony Petruzzi]
- Allow private methods to be used as controller filters - [#380](https://github.com/cfwheels/cfwheels/issues/380) [Tony Petruzzi]
- Fixed so the date form helpers can accept a blank string as the default value - [#391](https://github.com/cfwheels/cfwheels/issues/391) [Andy Bellenie]
- Fixed so that the "for" and "id" HTML attributes match when passing an empty string in "tagValue" - [#303](https://github.com/cfwheels/cfwheels/issues/303) [Tony Petruzzi]
- Added the datetime2 data type to the Microsoft SQL Server adapter - [#401](https://github.com/cfwheels/cfwheels/issues/401) [Per Djurner]
- Fixed so queries created in afterFind callbacks can be referenced from view helpers - [James Gibson]
- Fixed so links are properly hyphenated when controller/action is part of the placeholder route values. - [William Fisk, Per Djurner]

----

# [1.0] => 2009.11.24

### Model Enhancements

- Added "xml" datatype for SQL Server 2005/2008 - [#295](https://github.com/cfwheels/cfwheels/issues/295) [Andy Bellenie, Per Djurner]
- Added the Railo specific cfquery attribute called "psq" to make CFWheels run on a default installation of Railo - [Raul Riera, Per Djurner]
- Changed setProperties() to allow any passed in variable to be set on the object - [Per Djurner]
- Changed properties() so that it returns anything in the this scope that is not a function - [Per Djurner]
- Modified so SUM, AVG, MIN, MAX returns blank string and COUNT returns 0 when no records are found - [Tony Petruzzi, Per Djurner]
- Support for "if"/"unless" in validate(), validateOnCreate() and validateOnUpdate() - [Per Djurner]
- Support for built-in CFML types in validatesFormatOf() - [Raul Riera, Per Djurner]
- Added "allowBlank" argument on validatesUniquenessOf() - [#271](https://github.com/cfwheels/cfwheels/issues/271) [Per Djurner]
- Removed a query in findAll that didn't need to run when the join type was set to inner - [Mike Henke, Per Djurner]
- Updated model error functions to take and perform actions with properties and name errors - [Tony Petruzzi]

### View Enhancements

- Consistent style and reload links added to debug area - [Per Djurner]
- Trimmed final output's white space - [#279](https://github.com/cfwheels/cfwheels/issues/279) [Chris Peters, Per Djurner]
- Humanized list / array items in \$optionsForSelect() - [#267](https://github.com/cfwheels/cfwheels/issues/267) [James Gibson]

### Controller Enhancements

- Rewrite Rules for IIS7 - [Sameer Gupta, Mike Rampton, Per Djurner]
- Rewrite support in sub folders in Apache - [Peter Amiri]
- Turned off rewriting for "robots.txt" file - [#278](https://github.com/cfwheels/cfwheels/issues/278) [Chris Peters, Per Djurner]

### Bug Fixes

- Fixed AVG SQL calculation when dealing with integer values - [Tony Petruzzi, Per Djurner]
- Fixed so that CFID and CFTOKEN values do not get obfuscated when passed in the URL - [James Gibson]
- Fixed so javaScriptIncludeTag and styleSheetLinkTag can work with files with multiple dots in them - [#312](https://github.com/cfwheels/cfwheels/issues/312) [Mike Henke, Tony Petruzzi]
- Included calculated properties in the propertyNames(), reload(), updateAll(), deleteAll(), includePartial() and renderPartial() methods - [Per Djurner]
- Allow dynamic methods to be called through callbacks - [James Gibson, Per Djurner]
- Fixed so you can pass in the "properties" argument to dynamic methods (it was overridden previously) - [Per Djurner]
- Allow passing along the original where clause when paginating with a criteria on a joined table - Groups [Don Humphreys, Per Djurner]
- Removed unnecessary singularization for associations - Groups [Don Humphreys, Per Djurner]
- Fixed so validations respect the "allowBlank" setting - Groups [Raul Riera, Per Djurner]
- Corrected execution time report when reloading application - [Tony Petruzzi, Per Djurner]
- Allowing negative values in where clause - Groups [Don Humphreys, Tony Petruzzi]
- Work-around for a Railo mapping bug that was causing slowness - [#268](https://github.com/cfwheels/cfwheels/issues/268) [Tony Petruzzi, Per Djurner]
- Fixed an includePartial() error with caching that occurred in production mode - [#285](https://github.com/cfwheels/cfwheels/issues/285) [James Gibson, Per Djurner]
- Support passing in a single column query to select() and selectTag() - [#300](https://github.com/cfwheels/cfwheels/issues/300) [Tony Petruzzi]
- Fixed radio button ids to work properly with negative number values - [#274](https://github.com/cfwheels/cfwheels/issues/274) [Elezotte, Per Djurner]
- Removed display of "rewrite.cfm" in error emails - [#280](https://github.com/cfwheels/cfwheels/issues/280) [Raul Riera, Per Djurner]
- Fix for layout handling in sendEmail() on multipart emails - [#269](https://github.com/cfwheels/cfwheels/issues/269) [Chris Peters, Per Djurner]
- Throw CFWheels errors based on the "showErrorInformation" setting instead of production mode - [#276](https://github.com/cfwheels/cfwheels/issues/276) [Tony Petruzzi, Per Djurner]
- Fixed so includePartial() / renderPartial() returns a blank string when passed an empty array instead of an error - [#287](https://github.com/cfwheels/cfwheels/issues/287) [James Gibson, Per Djurner]
- Fixed a problem with file naming and case on Linux / Unix when using helpers and plugins - [Chris Peters, Per Djurner]
- Fixed so pagination aborts early when no records exist in the table instead of causing an error - Groups [Per Djurner, James Gibson]
- Fixed so return type is correct when no records are found on using findOne() with returnAs="object" - [Raul Riera, Per Djurner]
- Fixed Railo bug caused by argument defaults on a number of functions - [#201](https://github.com/cfwheels/cfwheels/issues/201), #264 [William Fisk, Tony Petruzzi, Per Djurner]
- Fixed so you can order on included tables in finders without specifying table name - [Per Djurner]
- Fixed so pagination returns an empty query instead of the full record set when specifying a page out of range - [Per Djurner]

### Miscellaneous

- Support for setting Application.cfc this scoped variables through config/app.cfm - [#315](https://github.com/cfwheels/cfwheels/issues/315) [Jay McEntire, Per Djurner]
- Allow plugin developer to specify a list of supported CFWheels versions instead of just one - [Chris Peters, Per Djurner]
- Methods from plugins can now be injected to "Application.cfc" - [#288](https://github.com/cfwheels/cfwheels/issues/288) [James Gibson, Per Djurner]
- Refactored validations code - [#266](https://github.com/cfwheels/cfwheels/issues/266) [Per Djurner]
- Copied cgi scope to request scope - [#277](https://github.com/cfwheels/cfwheels/issues/277) [Tony Petruzzi, James Gibson, Per Djurner]
- Removed an unnecessary variable assignment - [#265](https://github.com/cfwheels/cfwheels/issues/265) [William Fisk, Per Djurner]
- Added informative error messages for common CFWheels mistakes - [James Gibson, Per Djurner]
