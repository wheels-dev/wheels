---
title: CFWheels 1.4.2 maintenance release
slug: cfwheels-1-4-2-maintenance-release
publishedAt: '2015-08-31T16:54:57.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 1-4
categories:
  - Releases
excerpt: >-
  Today sees another maintenance release for the 1.4.x series Download 1.4.2
  today(https://github.com/cfwheels/cfwheels/releases/download/v1.4.2/cfwheels.1.4.2.zip)
  to fix the following:
coverImage: null
legacyId: '82'
---
Today sees another maintenance release for the 1.4.x series [Download 1.4.2 today](https://github.com/cfwheels/cfwheels/releases/download/v1.4.2/cfwheels.1.4.2.zip) to fix the following:

### Bug Fixes

-   Fix for selecting distinct with calculated property - \[Edward Chanter, Per Djurner\]
-   Fixed so default values are applied to non persistent properties - #519 \[Andy Bellenie\]
-   Fixed missing var scope causing error on Lucee - \[Russ Michaels, Tom King\]
-   Don't show debug info on AJAX requests - #496 \[Leroy Mah, Per Djurner\]
-   Fixed permissions issue with imageTag() when running on shared hosting - \[Per Djurner\]
-   Removed use of ExpandPath() in debug file since it was causing file permission issues - \[Peter Hopman, Per Djurner\]
-   Skip setting object property when NULL is passed in - #507 \[Andy Bellenie, Per Djurner\]
-   Fixed edge case issue with calling dynamic association methods - #501 \[Dominik Hofer, Per Djurner\]
-   Fixed lock name in onSessionEnd event - #499 \[Per Djurner\]
-   Ignore white space in the "where" argument to finders - #503 \[Per Djurner\]
-   Ignore spaces in the "keys" argument to hasManyCheckBox() and hasManyRadioButton() - \[Song Lin, Per Djurner\]
-   Skip running callbacks when validating uniqueness and similar situations - #492 \[Andy Bellenie, Per Djurner\]
-   Avoid plugin directory exception during first application load - #541 \[Adam Chapman, Per Djurner\]
-   Fix for using cfscript operators in "condition" and "unless" argument on ACF 8 - #531 \[Per Djurner\]
-   Fix for rolling back nested properties - #539 \[James Gibson, Chris Peters, Per Djurner\]
-   afterSave and afterCreate callbacks are not firing on nested objects - #525 \[Adam Chapman, Chris Peters, Per Djurner\]
-   Ability to pass in list to "includeBlank" argument on dateSelect() and similar functions - #502 \[Thorsten Eilers, Per Djurner\]
-   Ability to set attributes on the input element created by buttonTo() - \[Per Djurner\]
-   Added missing "onlyPath" argument to imageTag() - #508 \[Per Djurner\]
-   Corrected output of property labels in error messages - #494 \[Andy Bellenie\]

Also don't forget to check the [upgrade notes](http://docs.cfwheels.org/v1.4/docs/upgrading).
