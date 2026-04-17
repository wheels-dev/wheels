---
title: CFWheels 2.3.0-rc.1 Released
slug: cfwheels-2-3-0-rc-1
publishedAt: '2022-05-03T16:28:19.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags:
  - 2-3-0-rc-1
categories:
  - Releases
excerpt: >-
  This version has been cooking for a while and there have been many
  contributors. But since this is my first release a the helm with a new CI
  pipeline in place, I felt more comfortable doing a Relea...
coverImage: null
legacyId: '114'
---
This version has been cooking for a while and there have been many contributors. But since this is my first release a the helm with a new CI pipeline in place, I felt more comfortable doing a Release Candidate first.

[Download Zip](https://github.com/cfwheels/cfwheels/releases/download/v2.3.0-rc.1/cfwheels-variants.zip)

### If updating from CFWheels 2.2.x:

If should be an easy upgrade, just swap out the `wheels` folder.

## Changelog

### View Enhancements

-   Adds association error support via `includeAssociations` argument [#1080](https://github.com/cfwheels/cfwheels/issues/1080) - \[Nikolaj Frey\]

### Bug Fixes

-   onerror handler should increase user defined requestTimeout value [#1056](https://github.com/cfwheels/cfwheels/issues/1056) - \[Adam Chapman\]
-   deletedAt should also respect timestamp mode (UTC) [#1063](https://github.com/cfwheels/cfwheels/issues/1063) - \[David Belanger\]
-   Fixes No output from `Debug()` usage in plugin test cases [#1061](https://github.com/cfwheels/cfwheels/issues/1063) - \[Tom King\]
-   Development mode will now properly return a 404 status if view not found [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - \[Adam Cameron, Tom King\]
-   404 status now properly returned without URL rewriting [#1067](https://github.com/cfwheels/cfwheels/issues/1067) - \[Adam Cameron, Tom King\]
-   Internal Docs in ACF2018 should now not display duplicate categories \[Tom King\]
-   Internal Docs search now resets itself properly on backspace with empty value [#982](https://github.com/cfwheels/cfwheels/issues/982) - \[Brandon Shea, Tom King\]
-   `ValidatesConfirmationOf()` now correctly enforces prescence of confirmation property [#1070](https://github.com/cfwheels/cfwheels/issues/1070) - \[Adam Cameron, Tom King\]
-   `resource()`/`resources()` now allows empty `only` property to utilise as non-route parent [#1083](https://github.com/cfwheels/cfwheels/issues/1083) - \[Brian Ramsey\]
-   Handle XSS Injection in development enviroment - \[Michael Diederich\]
-   Fix params bug in CLI API \[[#1106](https://github.com/cfwheels/cfwheels/pull/1106)\] - \[Peter Amiri\]

### Miscellaneous

-   Update Docker Lucee Commandbox version to 5.2.0 - \[Adam Chapman, Tom King\]
-   Minor internal obselete reference to modelComponentPath removed - \[Adam Chapman, Tom King\]
-   Minor visual fix for long migration logs overflow in modal (scroll) - \[Brian Ramsey\]
-   Add test suite for Lucee and H2 Database to the GitHub Actions test suite. - \[Peter Amiri\]
-   On going changes to update the H2 drivers \[[#1107](https://github.com/cfwheels/cfwheels/pull/1107)\] - \[Peter Amiri\]
-   Fixes some syntax formating introduced by cfformat \[[#1111](https://github.com/cfwheels/cfwheels/pull/1111)\] - \[Adam Chapman\]
-   Minimum ColdFusion version is now ColdFusion (2018 release) Update 3 (2018,0,03,314033) / ColdFusion (2016 release) Update 10 (2016,0,10,314028) / ColdFusion 11 Update 18 (11,0,18,314030) [#923](https://github.com/cfwheels/cfwheels/issues/923) - \[Michael Diederich\]
-   Wheels save(allowExplicitTimestamps=true) doesn't produce the expected result \[[#1113](https://github.com/cfwheels/cfwheels/pull/1113)\] - \[SebastienFCT\]

### Potentially Breaking Changes

-   Automatic Time Stamps: the **deletedAt** column was using the server's local time for the timestamp while **createdAt** / **updatedAt** were using the timestamp selected for the timestamp mode. The default for CFWheels' timestamp mode is UTC and therefore all future **deletedAt** timestamps will be in UTC unless you've changed the default. Please review any SQL that uses **deletedAt** for datetime comparison.
