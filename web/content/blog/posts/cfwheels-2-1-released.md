---
title: CFWheels 2.1 Released
slug: cfwheels-2-1-released
publishedAt: '2020-04-12T12:55:52.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 2-1
categories:
  - Releases
excerpt: >-
  Today sees the release of CFWheels 2.1. Only a couple of bug fixes since the
  beta, so please refer to the
  changelog(https://github.com/cfwheels/cfwheels/blob/master/CHANGELOG.md) for a
  list of all ...
coverImage: null
legacyId: '106'
---

Today sees the release of CFWheels 2.1. Only a couple of bug fixes since the beta, so please refer to the [changelog](https://github.com/cfwheels/cfwheels/blob/master/CHANGELOG.md) for a list of all changes.

[Download now](https://github.com/cfwheels/cfwheels/releases/download/v2.1.0/cfwheels-2.1.0.zip) (zip)

If updating from CFWheels 2.0.x:

- replace your `wheels` folder from the one in the download, and
- outside the `wheels` folder, ensure you've got a file at `events/onabort.cfm` and create it if needed.
- rename any instances of `findLast`() to `findLastOne()` (this has been changed due to Lucee 5.3 having a new inbuilt function called findLast() which clashes with the wheels internals)

Happy Easter, and stay safe!
