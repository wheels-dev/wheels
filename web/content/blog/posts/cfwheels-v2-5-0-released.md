---
title: CFWheels v2.5.0 Released
slug: cfwheels-v2-5-0-released
publishedAt: '2023-11-05T00:51:22.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags:
  - 2-5
categories:
  - Community
excerpt: >-
  This is a major milestone release of CFWheels v2.5.0 that has been in the
  works for over a year. As you can see nearly 34 PRs have been merged into the
  codebase which include many enhancements and ...
coverImage: null
legacyId: '127'
---
This is a major milestone release of CFWheels v2.5.0 that has been in the works for over a year. As you can see nearly 34 PRs have been merged into the codebase which include many enhancements and bug fixes. In addition many changes have been made to the tooling used in the project.

Here are some of the highlights:

-   We have begun to publish SNAPSHOTS to ForgeBox.io on each successful commit to the develop branch.
-   The GitHub Actions CI scripts use the same configuration files as the local Docker testing suite. If you are inclined to contribute to the CFWheels project you will most likely want to be able to run the test suite locally in Docker containers to test your changes before you submit a PR. To run the local test suite simply type `docker compose up` in the root of your project. The source code is injected into the containers dynamically so it makes it easier to make changes and see them appear in the docker containers without rebuilding the containers. Look for more details on this to come in the future.
-   Every commit is now tested across a matrix of 20 combinations of CF Engines and Databases. The matrix includes CF Engines (Lucee 5, Lucee 6, Adobe ColdFusion 2016, Adobe ColdFusion 2018, Adobe ColdFusion 2021, and Adobe ColdFusion 2023) and databases (H2, MS SQL Server, PostgreSQL, and MySQL).
-   Each successful commit automatically builds two packages on ForgeBox. One for the default template and one for the core CFWheels folder.

## Upgrading an Existing Project

The changes in this version are confined to the `wheels` directory so simply swapping out your `wheels` directory should be all you need to do to upgrade.

## Changelog

### Model Enhancements

-   PR-1183-Allow datasource argument in finders [#1183](https://github.com/cfwheels/cfwheels/pull/1183) - \[Adam Chapman\]
-   PR-1201-Issue [ORM create() fails object validation for not null columns with defaults #929](https://github.com/cfwheels/cfwheels/issues/929) validate not nullable columns with default [#1201](https://github.com/cfwheels/cfwheels/pull/1201) - \[Adam Chapman\]
-   PR-1202-Remove old oracle test workaround [#1202](https://github.com/cfwheels/cfwheels/pull/1202) - \[Adam Chapman\]
-   PR-1205-issue-1182-adds-simplelock-to-sql-caching [#1205](https://github.com/cfwheels/cfwheels/pull/1205) - \[Adam Chapman\]
-   PR-1222-Findall() performance bottleneck [#1222](https://github.com/cfwheels/cfwheels/pull/1222) - \[Adam Chapman\]
-   PR-1223-refactor-queryCallback-with-inbuilt-query-functions [#1223](https://github.com/cfwheels/cfwheels/pull/1223) - \[Adam Chapman\]
-   PR-1226-Invalid column not throwing exception in select argument [#1226](https://github.com/cfwheels/cfwheels/pull/1226) - \[Zain Ul Abideen\]
-   PR-1265-improve-performance-refactor-out-listfind [#1265](https://github.com/cfwheels/cfwheels/pull/1265) - \[Adam Chapman\]
-   PR-1260-Adds support for native query returnType [#1260](https://github.com/cfwheels/cfwheels/pull/1260) - \[Adam Chapman\]
-   PR-1249-Removed the original IF/ELSE condition that invalidates calculated props and added condition [#1240](https://github.com/cfwheels/cfwheels/pull/1249) - \[Zain Ul Abideen\]

### View Enhancements

-   PR-1254-issue 908 enable paginationLinks() to set active class on parent [#1254](https://github.com/cfwheels/cfwheels/pull/1254) - \[Zain Ul Abideen\]

### Bug Fixes

-   PR-1227-Return a numeric value if the primary key is Numeric [#1227](https://github.com/cfwheels/cfwheels/pull/1227) - \[Zain Ul Abideen\]
-   PR-1257-Checkbox bug when checkedvalue is not true [#1257](https://github.com/cfwheels/cfwheels/pull/1257) - \[Adam Chapman\]
-   PR-1246-set the default route if it is not passed in the function [#1246](https://github.com/cfwheels/cfwheels/pull/1246) - \[Zain Ul Abideen\]
-   PR-1256-issue 889 unable to duplicate component [#1256](https://github.com/cfwheels/cfwheels/pull/1256) - \[Zain Ul Abideen\]
-   PR-1253-Issue 580 select ambiguous column name using the wheels alias [#1253](https://github.com/cfwheels/cfwheels/pull/1253) - \[Zain Ul Abideen\]
-   PR-1245-Added afterFind callback hook in the findAll function in case of structs [#1245](https://github.com/cfwheels/cfwheels/pull/1245) - \[Zain Ul Abideen\]
-   PR-1302-Check for Reload Password when setting a url IP exception [#1302](https://github.com/cfwheels/cfwheels/pull/1302) - Peter Amiri

### Miscellaneous

-   PR-1175-restoreTestRunnerApplicationScope setting [#1175](https://github.com/cfwheels/cfwheels/pull/1175) - \[Adam Chapman\]
-   PR-1176-fix text in core readme file [#1176](https://github.com/cfwheels/cfwheels/pull/1176) - \[Per Djurner\]
-   PR-1177-fix text in base template readme file [#1177](https://github.com/cfwheels/cfwheels/pull/1177) - \[Per Djurner\]
-   PR-1178-fix text in default template file [#1178](https://github.com/cfwheels/cfwheels/pull/1178) - \[Per Djurner\]
-   PR-1185-adds-root-docker-volume [#1185](https://github.com/cfwheels/cfwheels/pull/1185) - \[Adam Chapman\]
-   PR-1200-Update the docker-compose command to docker compose v2 syntax [#1200](https://github.com/cfwheels/cfwheels/pull/1200/) - \[Adam Chapman, Peter Amiri\]
-   PR-1204-Add Lucee 6 to test matrix on local Docker test suite [#1204](https://github.com/cfwheels/cfwheels/pull/1204/) - \[Peter Amiri\]
-   PR-1203-ensure testing params maintained [#1203](https://github.com/cfwheels/cfwheels/pull/1203) - \[Adam Chapman\]
-   PR-1228-Adding addClass attribute in the function textField [#1228](https://github.com/cfwheels/cfwheels/pull/1228) - \[Zain Ul Abideen\]
-   PR-1230-Add Adobe 2021 Support to local Docker and GitHub Actions testing - [#1230](https://github.com/cfwheels/cfwheels/pull/1230) - Peter Amiri
-   PR-1264-update Lucee 6 version used for tests to latest [#1264](https://github.com/cfwheels/cfwheels/pull/1264) - \[Zac Spitzer - \* _New Contributor_ \*\]
-   PR-1241-Fix spelling and remove whitespace from link [#1241](https://github.com/cfwheels/cfwheels/pull/1241) - \[John Bampton\]
-   PR-1247-show the current git branch in the debug layout [#1247](https://github.com/cfwheels/cfwheels/pull/1247) - \[Michael Diederich\]
-   PR-1250-Added test framework functions in the docs [#1250](https://github.com/cfwheels/cfwheels/pull/1250) - \[Zain Ul Abideen\]
-   PR-1255-issue 1179 Downloaded the CDN files and changed paths in files [#1255](https://github.com/cfwheels/cfwheels/pull/1255) - \[Zain Ul Abideen\]

### Guides

-   PR-1198-Documentation-fixes [#1198](https://github.com/cfwheels/cfwheels/pull/1198) - \[Adam Chapman\]

[Download Zip File](https://github.com/cfwheels/cfwheels/archive/refs/tags/v2.5.0.zip)
