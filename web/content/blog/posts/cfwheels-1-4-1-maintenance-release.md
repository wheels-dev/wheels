---
title: CFWheels 1.4.1 maintenance release
slug: cfwheels-1-4-1-maintenance-release
publishedAt: '2015-05-30T17:37:00.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 1-4
categories:
  - Releases
excerpt: >-
  Today sees a small maintenance release for the 1.4.x series Download 1.4.1
  today(https://github.com/cfwheels/cfwheels/releases/download/v1.4.1/cfwheels.1.4.1.zip)
  to fix the following:
coverImage: null
legacyId: '81'
---
Today sees a small maintenance release for the 1.4.x series [Download 1.4.1 today](https://github.com/cfwheels/cfwheels/releases/download/v1.4.1/cfwheels.1.4.1.zip) to fix the following:

### Bug Fixes

-   Skip callbacks when running calculation methods  \[Adam Chapman, Per Djurner\]
-   Fixed rewrite rules so base URL is rewritten correctly on Apache  \[Jeremy Keczan, Per Djurner\]
-   Removed incorrect path info information set by Apache \[David Belanger, Per Djurner\]
-   Fixed routing bug when running from a sub folder on Adobe ColdFusion 10 - \[Brant Nielsen, Per Djurner\]
-   Made sure error emails never depend on application variables being set - \[Per Djurner\]

### Miscellaneous

-   Removed tests folder - \[Per Djurner\]
-   Updates to framework utility pages - Update logo, Fix links on congrats page to point to new documentation site - \[Chris Peters\]

Also don't forget to check the [upgrade notes](http://docs.cfwheels.org/v1.4/docs/upgrading)
