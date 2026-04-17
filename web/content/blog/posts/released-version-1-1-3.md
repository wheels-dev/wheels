---
title: 'Released: ColdFusion on Wheels Version 1.1.3'
slug: released-version-1-1-3
publishedAt: '2011-03-24T21:50:43.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags:
  - 1-1
categories:
  - Releases
excerpt: >-
  Today, we're releasing another maintenance release, ColdFusion on Wheels
  version 1.1.3. This release includes several bug fixes. Upgrade
  now(https://cfwheels.org/download) to increase the stability...
coverImage: null
legacyId: '65'
---
Today, we're releasing another maintenance release, ColdFusion on Wheels version 1.1.3. This release includes several bug fixes. [Upgrade now](https://cfwheels.org/download) to increase the stability of your Wheels applications. To upgrade from version 1.1.x, replace the wheels folder in your application to the new one included in the zip file. If you're upgrading from a version earlier than 1.1, there are [instructions and notes in the documentation](https://cfwheels.org/docs/1-1/chapter/upgrading-wheels). Here are the updates included in version 1.1.3, listed in the [CHANGELOG](http://github.com/cfwheels/cfwheels/blob/v1.1.3/wheels/CHANGELOG):

-   Allows for relative url linking to be turned off in `autoLink()`
-   Allow for default argument on `sendMail()` for `from`, `to`, and `subject`
-   You can now have bracket markers for all validation arguments
-   Columns marked as `NOT NULL` should allow for blank strings
-   Fixed issue with `$create()` supplying incorrect keys to `$query()`
-   The original transaction mode would not be respected during during callbacks
-   `"none"` transaction modes would never close
-   Incorrect `$cache` argument
-   Route formats prevented fullstops from being used in `params`
-   Controller in `params` should be upper camel case
-   `application` scope would not initialize in sub
-   `validatesUniquenessOf()` doesn't read soft-deletes
-   `paginationLinks()`: routes with page number marker variable would produce the wrong links

We'd like to extend a heart-felt thank you to everyone for continuing to support this project, submit bugs, and help resolve issues with the framework.
