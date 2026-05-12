---
title: ColdFusion on Wheels 1.1 Beta 1 Is Now Available
slug: 1-1-beta-1-available
publishedAt: '2010-12-10T22:25:50.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  After tons of work on some exciting new features, the core team is happy to
  release the first beta of ColdFusion on Wheels
  1.1(https://cfwheels.org/download) today. Now we are turning to the commun...
coverImage: null
legacyId: '55'
---

After tons of work on some exciting new features, the core team is happy to release the [first beta of ColdFusion on Wheels 1.1](https://cfwheels.org/download) today. Now we are turning to the community to help us find bugs and put the new features through their paces. We need your help! Here is a taste of some of the new features:

- [Nested properties](https://cfwheels.org/docs/1-1/chapter/nested-properties) allow you to save changes to an object and all of its children in a single call to `save()`, `create()`, or `update()`.
- All database calls are wrapped in [transactions](https://cfwheels.org/docs/1-1/chapter/transactions) by default.
- Wheels now supports [SQLite and H2](https://cfwheels.org/docs/1-1/chapter/requirements) databases.
- [Automatic validations](https://cfwheels.org/docs/1-1/chapter/object-validation) give Wheels the ability to introspect your database and automatically validate max lengths, presence of, and numericality of your data.
- You can now [respond with multiple output formats](https://cfwheels.org/docs/1-1/chapter/responding-with-multiple-formats) in a single controller action.
- [Automatic dependency handling](https://cfwheels.org/docs/1-1/chapter/associations) for your models' associated data is now available.
- [Nested layouts](https://cfwheels.org/docs/1-1/chapter/using-layouts) allow you to extend layouts and keep your view code DRY.
- A testing framework for your applications and plugins. (Documentation and details coming soon.)
- [cfwheels.org](../../) now allows you to browse reference guides and API documentation for both [1.0.x](../../docs/1-0) and [1.1.x](../../docs/1-1) versions of Wheels (and beyond).
- Many other major and minor improvements. See the [changelog](http://code.google.com/p/cfwheels/source/browse/trunk/wheels/CHANGELOG) for more details.

The core team will be fixing bugs and improving documentation over the next few weeks. We appreciate any feedback that you can give us in the [Google Group](http://groups.google.com/group/cfwheels) or the [issue tracker](http://code.google.com/p/cfwheels/issues/list). We have started a chapter in the docs on [upgrading from 1.0.x to 1.1.x](https://cfwheels.org/docs/1-1/chapter/upgrading-wheels) and will be adding to the instructions as we run across more gotchas. Now let's get going on continuing to improve the best ColdFusion framework out there!
