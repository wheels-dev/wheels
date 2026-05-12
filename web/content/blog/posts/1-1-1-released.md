---
title: ColdFusion on Wheels 1.1.1 Released
slug: 1-1-1-released
publishedAt: '2010-12-21T23:10:53.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  We're releasing ColdFusion on Wheels version
  1.1.1(https://cfwheels.org/download) today after identifying and fixing a few
  bugs reported over the past couple weeks. The upgrade should not affect cu...
coverImage: null
legacyId: '58'
---

We're releasing [ColdFusion on Wheels version 1.1.1](https://cfwheels.org/download) today after identifying and fixing a few bugs reported over the past couple weeks. The upgrade should not affect current 1.1 users, so we strongly encourage that you upgrade immediately. As with all releases in the 1.x cycle, you can upgrade by replacing the wheels folder in your current application with the new one from the zip file. Here is the list of issues resolved from the [CHANGELOG](http://code.google.com/p/cfwheels/source/browse/tags/1.1.1/wheels/CHANGELOG):

- Added number formatting on the value passed in to "count" in the pluralize() function
- Fixed renderWith() so that it works in all environment modes when returning JSON
- Fixed belongsTo association code when using composite keys
- Allow cfthread to be used in views
- Fixed paging code for non-parameterized queries
- Corrected bug in request verification when session management was disabled in Railo
- Changed "if" to "condition" (and deprecated) on all validation methods to get around the fact that "if" is a reserved word in cfscript
- Fixed autolink() so that it correctly links and escapes relative paths
- Fixed so including partials with layouts does not cause duplicated content

Let's keep squashing these bugs, so be sure to share your experiences with the framework in the [Google Group](http://groups.google.com/group/cfwheels) and the [issue tracker](http://code.google.com/p/cfwheels/issues/list).
