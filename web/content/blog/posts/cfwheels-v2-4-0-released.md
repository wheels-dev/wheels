---
title: CFWheels v2.4.0 Released
slug: cfwheels-v2-4-0-released
publishedAt: '2022-08-23T15:35:37.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - Community
excerpt: >-
  This version is the accumulation of bug fixes and minor enhancements over the
  last quarter. This release welcomes John Bampton and Coleman Sperando, two
  first time contributors to the project.
coverImage: null
legacyId: '124'
---

This version is the accumulation of bug fixes and minor enhancements over the last quarter. This release welcomes John Bampton and Coleman Sperando, two first time contributors to the project.

[Download Zip](https://github.com/cfwheels/cfwheels/releases/download/v2.4.0%2B1/cfwheels-2.4.0.zip)

### If updating from CFWheels 2.3.x:

It should be an easy upgrade, just swap out the `wheels` folder.

### If you installed CFWheels with CommandBox and have a box.sjon file:

Enter `install cfwheels` in the root of your site to update your `wheels` folder to the latest.

## Changelog

### Bug Fixes

- issue-1091-wheels-paths-in-error-template [#1091](https://github.com/cfwheels/cfwheels/issues/1091) - \[Adam Chapman\]
- issue-1082-validations should not trim properties [#1082](https://github.com/cfwheels/cfwheels/issues/1082) - \[Adam Chapman\]
- issue-1088-Adds SQL parsing regex tweak which correctly handles whitespace [#1088](https://github.com/cfwheels/cfwheels/issues/1088) - \[Adam Chapman, Adam Cameron\]

### Miscellaneous

- Adds cfformat ignore marker comments around core "view" cfm files that contain html markup - \[Adam Chapman\]
- Adds the ability to scroll large items horizontally in the test runner UI [#1130](https://github.com/cfwheels/cfwheels/pull/1130) - \[Adam Chapman\]
- Fix cfformat ignore markers [#1129](https://github.com/cfwheels/cfwheels/pull/1129) - \[Adam Chapman\]
- Enable finder model methods to returnAs "sql", mainly for debugging [#1141](https://github.com/cfwheels/cfwheels/pull/1141) - \[Adam Chapman\]
- Show the Test Runner buttons in the CFWheels GUI on the Package List screen allowing the developer to run the entire test suite instead of one package at a time. - \[Peter Amiri\]
- The Base Template now contains all necessary placeholders for the CLI to interact with the application and be able to inject code properly. - \[Peter Amiri\]
- By default the Core tests will run in the application datasource, but the developer can setup a different database for running the Core tests to ensure there is no side effects from running the tests. If you do end up setting a different database for the coreTestDatasourceName, make sure to reload your application after running the Core tests. - \[Peter Amiri\]
- Fix two broken links in README. \[[#1150](https://github.com/cfwheels/cfwheels/pull/1150)\] - \[John Bampton - \* *New Contributor* \*\]
- Fix spelling \[[#1151](https://github.com/cfwheels/cfwheels/pull/1151)\]\[[#1158](https://github.com/cfwheels/cfwheels/pull/1158)\] - \[John Bampton - \* *New Contributor* \*\]
- Add .env parser to parse .env files and add the properties found in the file to this.env scope. [#1157](https://github.com/cfwheels/cfwheels/pull/1157) - \[Peter Amiri\]
- Update the local test suite to supported ARM architecture docker images to make the suite compatible with the Apple Silicon Macs. [#1143](https://github.com/cfwheels/cfwheels/pull/1143) - \[Peter Amiri\]

### Guides

- Fix broken links throughout the guides. - \[Peter Amiri\]
- Fixed mailto link in CONTRIBUTING.md [#1123](https://github.com/cfwheels/cfwheels/pull/1123) - \[Coleman Sperando \* *New Contributor* \*\]
- Fix test guides examples [#1125](https://github.com/cfwheels/cfwheels/pull/1125) \[Adam Chapman\]
- Fix typos in the guides [#1161](https://github.com/cfwheels/cfwheels/pull/1161) \[Adam Chapman\]
