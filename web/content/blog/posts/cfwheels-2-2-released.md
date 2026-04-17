---
title: CFWheels 2.2 Released
slug: cfwheels-2-2-released
publishedAt: '2020-11-22T13:11:31.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags: []
categories:
  - Releases
excerpt: >-
  It's been a while coming. Can I blame the pandemic? Lots of nice little tweaks
  and fixes in this version. Please see the
  changelog(https://github.com/cfwheels/cfwheels/blob/v2.2.0/CHANGELOG.md)
  for...
coverImage: null
legacyId: '107'
---
It's been a while coming. Can I blame the pandemic? Lots of nice little tweaks and fixes in this version. Please see the [changelog](https://github.com/cfwheels/cfwheels/blob/v2.2.0/CHANGELOG.md) for all details.

[Download zip](https://github.com/cfwheels/cfwheels/releases/download/v2.2.0/cfwheels-2.2.0.zip)

**If updating from CFWheels 2.1.x:**

It should be an easy upgrade , just swap out the `wheels` folder.

**If updating from CFWheels 2.0.x:**

-   replace your `wheels` folder from the one in the download, and
-   outside the `wheels` folder, ensure you've got a file at `events/onabort.cfm` and create it if needed.
-   rename any instances of `findLast`() to `findLastOne()` (this has been changed due to Lucee 5.3 having a new inbuilt function called findLast() which clashes with the wheels internals)

As always, a huge thanks to all contributors - stay safe out there!
