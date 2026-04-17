---
title: ColdFusion on Wheels Version 1.1.2 Released Today
slug: version-1-1-2-released-today
publishedAt: '2011-02-01T20:19:24.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags:
  - 1-1
categories:
  - Releases
excerpt: >-
  We're releasing ColdFusion on Wheels version 1.1.2 today, which includes
  several bug fixes. Upgrade immediately(https://cfwheels.org/download) to
  increase the stability of your Wheels application. ...
coverImage: null
legacyId: '64'
---
We're releasing ColdFusion on Wheels version 1.1.2 today, which includes several bug fixes. [Upgrade immediately](https://cfwheels.org/download) to increase the stability of your Wheels application. As with all releases in the 1.x cycle, you can upgrade by replacing the wheelsfolder in your current application with the new one from the zip file. Here is a list of issues resolved from the [CHANGELOG](https://github.com/cfwheels/cfwheels/blob/v1.1.2/wheels/CHANGELOG):

-   `select()`, `selectTag()` allow an array of structs to be passed to options
-   Changed `default` argument on includeContent() to `defaultValue`
-   Add `when` argument to `validate()`
-   Added the `varchar_ignorecase` type to the H2 adapter
-   Fix so that the full table name is always retuned
-   Pagination with `parameterize` set to `false` for numeric keys
-   Blank should be the selected value when `includeBlank` is set in `select()`
-   `validatesLengthOf()` failed when both maximum and minimum were specified

Thanks everyone for your support. Please continue to share your experiences in the [Google Group](http://groups.google.com/group/cfwheels) and submit issues and feature requests to the [issue tracker](http://code.google.com/p/cfwheels/issues/list).
