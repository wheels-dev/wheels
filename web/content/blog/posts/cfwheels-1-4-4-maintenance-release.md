---
title: CFWheels 1.4.4 maintenance Release
slug: cfwheels-1-4-4-maintenance-release
publishedAt: '2015-12-10T15:30:33.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 1-4
categories:
  - Releases
excerpt: >-
  Today sees another maintenance release for the 1.4.x series Download 1.4.4
  today(https://github.com/cfwheels/cfwheels/releases/download/v1.4.4/cfwheels.1.4.4.zip)
  to fix the following:
coverImage: null
legacyId: '84'
---
Today sees another maintenance release for the 1.4.x series [Download 1.4.4 today](https://github.com/cfwheels/cfwheels/releases/download/v1.4.4/cfwheels.1.4.4.zip) to fix the following:

### Bug Fixes

-   Check global "cacheActions" setting - #572 \[Andy Bellenie, Per Djurner\]
-   Fixed parsing for SQL IN parameters - #564 \[Lee Bartelme, Per Djurner\]
-   Pass through all arguments properly when using findOrCreateBy - #561 \[Per Djurner\]
-   Make it possible to disable session management on a per request basis - #493 \[Andy Bellenie, Per Djurner\]
-   Allow mailParams to be passed through to sendEmail() - #565 \[Tom King\]
-   Fixed inconsistency in form helpers for nested properties - \[Marc Funaro, Per Djurner, Chris Peters\]
-   Fixed issue with grouping on associated models - \[Song Lin, Per Djurner\]
-   Made the pagination() function available globally - #560 \[Chris Peters, Per Djurner\]

Also don't forget to check the [upgrade notes](http://docs.cfwheels.org/v1.4/docs/upgrading).
