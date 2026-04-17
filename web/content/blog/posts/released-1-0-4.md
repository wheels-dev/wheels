---
title: 'Released: ColdFusion on Wheels 1.0.4'
slug: released-1-0-4
publishedAt: '2010-12-21T19:28:08.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  Today we're releasing ColdFusion on Wheels version
  1.0.4(https://cfwheels.org/download). This release fixes another round of bugs
  and adds more stability improvements. Download it now(https://cfwhe...
coverImage: null
legacyId: '50'
---
Today we're releasing [ColdFusion on Wheels version 1.0.4](https://cfwheels.org/download). This release fixes another round of bugs and adds more stability improvements. [Download it now](https://cfwheels.org/download), replace the wheels folder with the new one, and reload your application. If you're upgrading from a version earlier than 1.0, [follow these instructions](https://cfwheels.org/docs/chapter/upgrading-wheels). From the change log at wheels/CHANGELOG:

-   Added missing support for passing in array of model objects as options to select() - #411
-   Fixed so "afterFind" callback methods are only called once during pagination - #435
-   Added "prependOnAnchor" and "appendOnAnchor" arguments to paginationLinks() to get around an issue where the "appendToPage" string was added on anchor pages - #434
-   Fixed bug in paginationLinks() when using "appendToPage" with single page result
-   Fixed bug with count() when using composite primary keys
-   Fixed concurrency issue related to setting the model name on associations - #419
-   Fix for skipping duplicate columns returned from cfdbinfo when using Oracle - #437 & #439
-   Fix for race conditions when setting the join clause in an application scoped model object - #432
-   Fixed so URLFor() is not duplicating controller and action when URL rewriting is off - #433
-   Added support to imageTag() for all image types that the CFML engine supports
