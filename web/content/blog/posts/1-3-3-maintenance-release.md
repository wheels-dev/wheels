---
title: CFWheels 1.3.3 maintenance release
slug: 1-3-3-maintenance-release
publishedAt: '2015-02-02T23:42:45.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Chris Peters
tags:
  - 1-3
categories:
  - Releases
excerpt: >-
  Today, we release the third maintenance release in the 1.3.x series. Download
  version 1.3.3(https://cfwheels.org/download) to fix the following bugs:
coverImage: null
legacyId: '79'
---

Today, we release the third maintenance release in the 1.3.x series. [Download version 1.3.3](https://cfwheels.org/download) to fix the following bugs:

- Correct output of boolean HTML attributes using new global `booleanAttributes` setting
- Make sure locks cannot be affected by other applications running on the same server
- Fixed bug with updating an integer column from `NULL` to `0`
- Fixed potential permissions issue when running on shared hosting

More info in the [1.3.3 CHANGELOG](https://github.com/cfwheels/cfwheels/blob/v1.3.3/wheels/CHANGELOG). If you're upgrading from 1.3.0+, you just need to replace the `wheels` folder with the new one from the download. If you're upgrading from an older version of CFWheels, see the [instructions](https://cfwheels.org/docs/1-3/chapter/upgrading-wheels).
