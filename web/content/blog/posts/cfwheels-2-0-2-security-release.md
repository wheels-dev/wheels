---
title: CFWheels 2.0.2 Security Release
slug: cfwheels-2-0-2-security-release
publishedAt: '2019-10-17T18:44:27.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 2-0
  - 2-0-1
categories:
  - Releases
excerpt: Today sees a security release for the 2.x series.
coverImage: null
legacyId: '103'
---

Today sees a security release for the 2.x series.

It is strongly recommended to update to CFWheels 2.0.2 if you are running either 2.0.0 or 2.0.1. This issue does **not** affect 1.x releases. This release introduces a potentially breaking change, so you are encouraged to test your application appropriately before deploying. Thanks to Bryan Welter for bringing it to our attention.

[Download 2.0.2](https://github.com/cfwheels/cfwheels/releases/download/2.0.2/cfwheels-2.0.2.zip)

### Potential Breaking Changes

- Blank strings in SQL are no longer converted to null
