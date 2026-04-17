---
title: CFWheels 1.4.3 maintenance release
slug: cfwheels-1-4-3-maintenance-release
publishedAt: '2015-10-16T14:55:33.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 1-4
categories:
  - Releases
excerpt: >-
  Today sees another maintenance release for the 1.4.x series Download 1.4.3
  today(https://github.com/cfwheels/cfwheels/releases/download/v1.4.3/cfwheels.1.4.3.zip)
  to fix the following:
coverImage: null
legacyId: '83'
---
Today sees another maintenance release for the 1.4.x series [Download 1.4.3 today](https://github.com/cfwheels/cfwheels/releases/download/v1.4.3/cfwheels.1.4.3.zip) to fix the following:

### Bug Fixes

-   Fix for using cfscript operators in condition and unless arguments.
-   Added try / catch on getting host name since CreateObject("java") can be unavailable for security reasons.
-   Fixed bug with cache keys always changing even though the input was the same.
-   Remove white space character in output.
-   Use correct path info in error email and debug area.
-   Fixed plugin injection issue on start-up.
-   Skip calculated properties that are aggregate SQL functions in the GROUP BY clause.
-   Fixed error when trying to validate uniqueness on blank numeric properties.

Also don't forget to check the [upgrade notes](http://docs.cfwheels.org/v1.4/docs/upgrading).
