---
title: Download ColdFusion on Wheels 0.9.3
slug: download-0-9-3
publishedAt: '2009-12-10T20:27:47.000Z'
updatedAt: '2025-05-19T22:32:18.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  Wheels matures a little more with version 0.9.3. Download it
  today.(http://www.cfwheels.org/download) For those of you upgrading from
  Wheels 0.9.2, the most that you'll probably need to do is delet...
coverImage: null
legacyId: '6'
---

Wheels matures a little more with version 0.9.3. [Download it today.](http://www.cfwheels.org/download) For those of you upgrading from Wheels 0.9.2, the most that you'll probably need to do is delete the wheels folder from your install and replace it with the new wheels folder. Voila! What's new in this release?

## Bug Fixes

- Fixes to make Wheels run better on [Railo 3.1](http://www.getrailo.com/) and the upcoming [Adobe ColdFusion 9](http://labs.adobe.com/wiki/index.php/Centaur).
- Fix to make it possible to use routes in forms.
- Fix so that functions added to the events/functions.cfm file are globally available in the application and not just from ColdFusion events.
- Fixes to the Oracle database adapter.
- Fixes to make the ORM work better when mapping properties to columns with different names.
- …and more minor fixes.

## Feature Enhancements

- [Partials](http://www.cfwheels.org/docs/chapter/partials) now allow you to pass a query, which will cause the partial to be run for every record in the query.
- Improvement to the simpleFormat() function.
- Improvements for display of [pagination links](http://www.cfwheels.org/docs/chapter/displaying-links-for-pagination).
- For security reasons, Wheels will now abort all requests that don't go through index.cfm or rewrite.cfm in the root.

## New Functionality

- Added 3 new [object callback](http://www.cfwheels.org/docs/chapter/object-callbacks) types: afterNew(), afterFind(), and afterInitialization().
- Support for the PostgreSQL DBMS.
- Support for setting default values on objects based on the database settings (through the new(), create(), and save() methods).
- New dependent setting for [associations](http://www.cfwheels.org/docs/chapter/associations), which decides which join type to use in queries and whether or not to delete associated objects when the parent is deleted.

Watch for updates to the [Documentation](http://www.cfwheels.org/docs) over the next few days.
