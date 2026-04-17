---
title: CFWheels 1.3.1 maintenance release
slug: 1-3-1-maintenance-release
publishedAt: '2014-08-25T21:22:49.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Chris Peters
tags:
  - 1-3
categories:
  - Releases
excerpt: >-
  We have fixed a few bugs discovered by the community after releasing CFWheels
  1.3.0 a few weeks ago and packaged them as version 1.3.1. Behold the major
  fixes released in version 1.3.1(https://cfwh...
coverImage: null
legacyId: '77'
---
We have fixed a few bugs discovered by the community after releasing CFWheels 1.3.0 a few weeks ago and packaged them as version 1.3.1. Behold the major fixes released in [version 1.3.1](https://cfwheels.org/download):

-   Fixed issue with calling `addFormat()` on application start-up.
-   Fixed so that Railo outputs IDs for nested properties as integers instead of exponents.
-   Make sure that IDs for nested properties are unique.

See the [v1.3.1 CHANGELOG](https://github.com/cfwheels/cfwheels/blob/v1.3.1/wheels/CHANGELOG) for a full record of all changes. To upgrade from 1.3.0, replace the `wheels` folder in your application with the new one from the zip file. See the [instructions](https://cfwheels.org/docs/1-3/chapter/upgrading-wheels) if you're upgrading from an earlier release. Keep rocking, CFWheels community! \\m/
