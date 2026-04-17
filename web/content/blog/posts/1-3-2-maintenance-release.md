---
title: CFWheels 1.3.2 maintenance release
slug: 1-3-2-maintenance-release
publishedAt: '2014-11-12T01:04:33.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Chris Peters
tags:
  - 1-3
categories:
  - Releases
excerpt: >-
  Today we release the second maintenance release in the 1.3.x series. Download
  version 1.3.2(https://cfwheels.org/download) to fix the following bugs:
coverImage: null
legacyId: '78'
---
Today we release the second maintenance release in the 1.3.x series. [Download version 1.3.2](https://cfwheels.org/download) to fix the following bugs:

-   Fixed regression bug with setting unique id for nested properties
-   Fixed reversed usage for setting option text/value when passing in an array of structs to `select()` / selectTag()
-   Tableless models should not require `dataSourceName` - #351
-   Fixed issue with using group by with calculated properties - #89
-   Fixed ORM incorrectly parsing a property value as `NULL` - #209
-   Fixed bug with application scope when sharing name across applications - #359
-   Fix for removing `AS` from `ORDER BY` clause in Microsoft SQL Server - #132
-   Calling `valid()` will now correctly validate all associations when using nested properties - #284
-   Fixed issue with `save()`causing callbacks to run twice when using nested properties - #284
-   Fixed race condition issue with caching - #376
-   Fixed number parsing in `WHERE` strings

More info in the [1.3.2 CHANGELOG](https://github.com/cfwheels/cfwheels/blob/v1.3.2/wheels/CHANGELOG). If you're upgrading from 1.3.0+, you just need to replace the `wheels` folder with the new one from the download. If you're upgrading from an older version of CFWheels, see the [instructions](https://cfwheels.org/docs/1-3/chapter/upgrading-wheels).
