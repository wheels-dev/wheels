---
title: CFWheels 2.0.1 maintenance Release
slug: cfwheels-2-0-1-maintenance-release
publishedAt: '2018-01-31T19:56:48.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 2-0
categories:
  - Releases
excerpt: >-
  Today sees a maintenance release for the 2.x series. Download 2.0.1
  today(https://github.com/cfwheels/cfwheels/releases/download/v2.0.1/cfwheels-2.0.1.zip)
  to fix the following:
coverImage: null
legacyId: '95'
---
Today sees a maintenance release for the 2.x series. [Download 2.0.1 today](https://github.com/cfwheels/cfwheels/releases/download/v2.0.1/cfwheels-2.0.1.zip) to fix the following:

### Bug Fixes

-   Fixes reload links on application test suite page - [#820](https://github.com/cfwheels/cfwheels/issues/820) \[Michael Diederich\]
-   Set `dbname` in `cfdbinfo` calls when using custom database connection string - [#822](https://github.com/cfwheels/cfwheels/issues/822) \[Per Djurner\]
-   Fixes `humanize()` function - [#663](https://github.com/cfwheels/cfwheels/issues/663) \[Chris Peters, Per Djurner, kmd1970\]
-   Enables the `rel` attribute for `stylesheetlinkTag()` - [#834](https://github.com/cfwheels/cfwheels/pull/834) \[Michael Diederich\]
-   Returning a `NULL` value from a query with NULL support enabled no longer throws an error - [#834](https://github.com/cfwheels/cfwheels/pull/834) \[Michael Diederich\]
-   Accessing a route with incorrect verb now provides a more useful error message - [#800](https://github.com/cfwheels/cfwheels/issues/800) \[Tom King\]
-   Fixed bug with arrays in URLs - [#836](https://github.com/cfwheels/cfwheels/issues/836) \[Michael Diederich, Per Djurner\]
-   startFormTag now properly applies the method attribute - [#837](https://github.com/cfwheels/cfwheels/issues/837) \[David Paul Belanger\]
-   Incompatible plugin notice now ignores patch releases unless specified - [#840](https://github.com/cfwheels/cfwheels/issues/840) \[Risto, Tom King\]
