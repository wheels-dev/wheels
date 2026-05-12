---
title: 'Released: ColdFusion on Wheels 1.0.5'
slug: released-1-0-5
publishedAt: '2010-12-18T15:27:44.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  It's my pleasure to announce the release of ColdFusion on Wheels version
  1.0.5. Upgrade now(https://cfwheels.org/download) to increase the stability of
  your codebase. We noticed that there were qui...
coverImage: null
legacyId: '53'
---

It's my pleasure to announce the release of ColdFusion on Wheels version 1.0.5. [Upgrade now](https://cfwheels.org/download) to increase the stability of your codebase. We noticed that there were quite a few bugs being squashed in the 1.1 cycle, so we back-ported most of them into the 1.0.x codebase, and that's how 1.0.5 was born. The [CHANGELOG](http://code.google.com/p/cfwheels/source/browse/branches/1.0/wheels/CHANGELOG) lists 23 bug fixes, many reported by the community.

- Fixed the handling for the `errorEmailServer` setting so that error emails can now be sent without having to set the server in the ColdFusion administrator
- Corrected pluralize rules
- Remove possible spaces in list passed in to callback registration
- Check to see that a function has a declaration in the settings before setting defaults
- Update to `capitalize()` to return nothing if the passed in string is empty
- `validatesPresenceOf()` now takes whitespace into account
- Fix for lock timeouts occurring during race conditions in the `design` and `development` modes
- Fix so Wheels uses passed in width/height in `imageTag()` when only one of them is passed in
- Don't append `.css`, `.js` to asset files when they end in `.cfm`
- Update to reload to catch the query blank boolean error
- `onCreate` validations do not run when `onSave` validations fail
- Fixes bug with nullable foreign keys in `where` clause
- Update to clean up variables from all scopes after running plugin injection
- Updated PostgreSQL types
- Fix for race condition when checking for existing controller files in the `design` and `development` modes
- Error in SQL Server pagination with mapped columns
- Updated `hasChanged()` for a race condition that wasn't met
- Fixed pagination error in Oracle when using the `include` argument
- Fixed incorrect layout rendering for `renderPartial()` and `includePartial()`
- Fix for complex `include` strings
- Fixed naming conflict occurring for properties starting with the same name as its model on included objects
- Fixed pluralization issue related to partials used with object(s)/queries and removed the limitation of the file being tied to the model name
- Prevent additional errors from occurring during display of CFML errors

The upgrade cycle is still simple: replace your wheels folder with the new wheels folder from the [1.0.5 zip](https://cfwheels.org/download) and then reload your application.
