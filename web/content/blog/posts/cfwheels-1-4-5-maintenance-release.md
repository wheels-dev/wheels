---
title: CFWheels 1.4.5 maintenance Release
slug: cfwheels-1-4-5-maintenance-release
publishedAt: '2016-03-30T17:09:04.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 1-4
categories:
  - Releases
excerpt: >-
  Today sees another maintenance release for the 1.4.x series Download 1.4.5
  today(https://github.com/cfwheels/cfwheels/releases/download/v1.4.5/cfwheels.1.4.5.zip)
  to fix the following:
coverImage: null
legacyId: '86'
---

Today sees another maintenance release for the 1.4.x series [Download 1.4.5 today](https://github.com/cfwheels/cfwheels/releases/download/v1.4.5/cfwheels.1.4.5.zip) to fix the following:

### Bug Fixes

- Display URL correctly in error email when on HTTPS - \[Per Djurner\]
- Added the datetimeoffset data type to the Microsoft SQL Server adapter - \[Danny Beard\]
- Fix for test link display in debug footer - #588 \[Tom King\]
- Don't include query string when looking for image on file through imageTag() - \[Per Djurner\]
- Format numbers in paginationLinks() - \[Per Djurner\]
- Correct plugin filename case on application startup - #586 \[Chris Peters\]
- Clear out cached queries on reload - #585 \[Andy Bellenie\]

Also don't forget to check the [upgrade notes](http://docs.cfwheels.org/v1.4/docs/upgrading).
