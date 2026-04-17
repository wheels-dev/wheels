---
title: CFWheels 2.0.0-beta.1 Now Available
slug: cfwheels-2-0-0-beta-1-now-available
publishedAt: '2017-06-01T15:20:01.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 2-0
categories:
  - Releases
excerpt: >-
  It's been about a year in the making, and well over 1000 commits, but the beta
  for 2.0 has now arrived! We're still catching up on the main documentation as
  there's so much to cover in this release...
coverImage: null
legacyId: '92'
---
It's been about a year in the making, and well over 1000 commits, but the beta for 2.0 has now arrived! We're still catching up on the main documentation as there's so much to cover in this release, so bear with us a bit! In the meantime, please do check it out:

-   Direct Download: [Download zip](https://github.com/cfwheels/cfwheels/releases/download/v2.0.0-beta.1/cfwheels-2.0.0-beta.1.zip)
-   Commandbox quick install : `install cfwheels@be` (Just downloads and unzips)
-   Commandbox install wizard via CFWheels CLI (with url rewriting included):  `wheels new` _(make sure your version of the CLI is up to date with `install cfwheels-cli`)_

Make sure to check the "Breaking Changes" section below, and [please report any bugs](https://github.com/cfwheels/cfwheels/issues).

* * *

#### Need a little help upgrading?

There will be some more posts coming up covering some of the big topics like routing & migrations, but in the meantime:

-   Check out Adam's [upgrade advisor plugin](https://github.com/chapmandu/UpgradeAdvisor) (Commandbox: `install upgradeadvisor`)
-   Get in touch via the Mailing List, Slack channel etc.

* * *

### Changelog

### Model Enhancements

-   Support for passing in `select=false` to `property()` to not include a calculated property by default in SELECT clauses - [#122](https://github.com/cfwheels/cfwheels/issues/122) \[Adam Chapman, Per Djurner\]
-   Support for setting calculated properties to a specific data type - \[Per Djurner\]
-   Support for `returnIncludedAs` and `returnIncluded` arguments to `properties()` for returning nested properties - \[Adam Chapman\]
-   Support for calling `updateProperty()` with dynamic argument, e.g. `updateProperty(firstName="Per")` - \[Per Djurner\]
-   Support for using boolean transaction argument, e.g. `update(transaction=false)` - [#654](https://github.com/cfwheels/cfwheels/issues/654) \[Adam Chapman\]
-   Support for MariaDB - [#563](https://github.com/cfwheels/cfwheels/issues/563) \[AlexeiCF, Adam Chapman\]
-   Model instance `isPersisted()` and `propertyIsBlank()` methods - [#559](https://github.com/cfwheels/cfwheels/issues/559) \[Chris Peters\]
-   Database Migrations (dbmigrate) now available in the core - [#664](https://github.com/cfwheels/cfwheels/issues/664) \[Adam Chapman, Tom King, Mike Grogan\]
-   Databases can now be automatically migrated to the latest version on application start - [#766](https://github.com/cfwheels/cfwheels/issues/766) \[Tom King\]
-   New `timeStampMode` setting (`"utc"`, `"local"` or `"epoch"`) for the `createdAt` and `updatedAt`columns - \[Andy Bellenie\]
-   Allow nested transactions - [#732](https://github.com/cfwheels/cfwheels/issues/732) \[Andy Bellenie\]
-   The `handle` argument to finders now set the variable name for the query so it's easier to find in the debug output - \[Per Djurner\]
-   Support added for HAVING when using aggregate functions in the `where` argument - [#483](https://github.com/cfwheels/cfwheels/issues/483) \[Per Djurner\]
-   Added support for the JSON data type in the MySQL adapter - [#759](https://github.com/cfwheels/cfwheels/issues/759) \[Joel Stobart\]
-   Corrected mapping for text types in the MySQL adapter - [#759](https://github.com/cfwheels/cfwheels/issues/759) \[Joel Stobart\]
-   Added global setting, `lowerCaseTableNames`, to always lower case table names in SQL statements - \[Per Djurner\]

### View Enhancements

-   `flashMessages()` are now in default layout.cfm - [#650](https://github.com/cfwheels/cfwheels/issues/650) \[Tom King\]
-   Added ability to override value in `textField()`, `passwordField()` and `hiddenField()` - [#633](https://github.com/cfwheels/cfwheels/issues/633) \[Per Djurner, Chris Peters\]
-   Support for the `method` argument in `buttonTo()` helper - [#761](https://github.com/cfwheels/cfwheels/issues/761) \[Adam Chapman\]

### Controller Enhancements

-   Support for HTTP verbs, scopes, namespaces, and resources in routes (ColdRoute) \[Don Humphreys, James Gibson, Tom King\]
-   Support for passing in `ram://` resources to `sendFile()` - [#566](https://github.com/cfwheels/cfwheels/issues/566) \[Tom King\]
-   Extended `sendMail()` so that it can return the text and/or html content of the email - [#122](https://github.com/cfwheels/cfwheels/issues/122) \[Adam Chapman\]
-   `renderWith()` can now set http status codes in header with the `status` argument - [#549](https://github.com/cfwheels/cfwheels/issues/549) \[Tom King\]
-   Cross-Site Request Forgery (CSRF) protection - [#613](https://github.com/cfwheels/cfwheels/issues/613) \[Chris Peters\]
-   Parse JSON body and add to params struct - \[Tom King, Per Djurner\]

### Bug Fixes

-   Fixes skipped model instantiation due to Linux file case sensitivity - [#643](https://github.com/cfwheels/cfwheels/issues/643) \[Adam Chapman, Tom King\]
-   Added spatial datatypes for MySQL - [#660](https://github.com/cfwheels/cfwheels/issues/660) \[Normal Cesar\]
-   Made `humanize()` keep spaces in input - [#663](https://github.com/cfwheels/cfwheels/issues/663) \[Per Djurner, Chris Peters\]
-   Avoid double redirect error when doing delayed redirects from a verification handler function - \[Per Djurner\]
-   Fixes attempts to insert nulls for blank strings - [#654](https://github.com/cfwheels/cfwheels/issues/654) \[Andy Bellenie, Per Djurner\]
-   Fix for using `validatePresenceOf()` with default on update - \[Andy Bellenie\]
-   Fixes so paginated finder calls with no records include column names - [#722](https://github.com/cfwheels/cfwheels/issues/722) \[Per Djurner\]
-   Fixes "invalid data" error when using unsigned integers in MySQL - [#768](https://github.com/cfwheels/cfwheels/issues/768) \[Per Djurner\]

### Plugins

-   Plugins now distributed via forgebox.io \[Tom King\]
-   Update to the plugin system to allow overriding of the same framework method multiple times - [#681](https://github.com/cfwheels/cfwheels/issues/681) \[James Gibson, Tom King\]
-   Added ability to turn off incompatible plugin warnings from showing - \[Danny Beard\]
-   Plugins now have any java lib/class files automatically mapped onApplicationStart [731](https://github.com/cfwheels/cfwheels/issues/731) \[Andy Bellenie, Tom King\]
-   Plugins now read version number off their `box.json` files and are displayed in debug area [#68](https://github.com/cfwheels/cfwheels/issues/68) \[Tom King\]
-   Plugin meta data as set in `box.json` now available in `application.wheels.pluginMeta` scope [#68](https://github.com/cfwheels/cfwheels/issues/68) \[Tom King\]

### Miscellaneous

-   Redirect away after a reload request - \[Chris Peters\]
-   Support checking IP in `http_x_forwarded_for` when doing maintenance mode exclusions - \[Per Djurner\]
-   Support checking user agent string when doing maintenance mode exclusions - \[Per Djurner\]
-   Added JUnit and JSON format test results - \[Adam Chapman\]
-   Added empty application test directories - \[Chris Peters, Adam Chapman\]
-   Added default `urlrewrite.xml` to support Tuckey URL rewriting with Commandbox [#649](https://github.com/cfwheels/cfwheels/issues/649) - \[Tom King\]
-   Added `beforeAll()`, `afterAll()`, `packageSetup()`, `packageTeardown()` methods to test framework [#651](https://github.com/cfwheels/cfwheels/issues/651) - \[Adam Chapman\]
-   Added `errorEmailFromAddress` and `errorEmailToAddress` config settings - [#95](https://github.com/cfwheels/cfwheels/issues/95) \[Andy Bellenie, Tony Petruzzi, Per Djurner\]
-   Support for passing in any "truthy" value to `assert()` in tests - \[Per Djurner\]
-   Added `/app/` mapping pointing to the root of the application - \[Per Djurner\]
-   Added a `processRequest()` function that simplifies testing controllers - \[Per Djurner\]
-   Added new embedded documentation viewer/generator for JavaDoc - [#734](https://github.com/cfwheels/cfwheels/issues/734) \[Tom King\]
-   Removes all references to Railo - [#656](https://github.com/cfwheels/cfwheels/issues/656) (Adam Chapman)
-   Made uncountable and irregular words configurable - [#739](https://github.com/cfwheels/cfwheels/issues/739) \[Per Djurner\]
-   Removed `design` mode - \[Per Djurner\]
-   Removed `cacheRoutes` setting - \[Per Djurner\]
-   The `cacheFileChecking` and `cacheImages` settings are now turned off in development mode - \[Per Djurner\]
-   Added `includeErrorInEmailSubject` setting - \[Per Djurner\]
-   Environment switching via URL can now be turned off via `allowEnvironmentSwitchViaUrl` - [#766](https://github.com/cfwheels/cfwheels/issues/766) \[Tom King\]

### Breaking Changes

-   Minimum Lucee version is now 4.5.5.006.
-   Minimum ACF version is now 10.0.23 / 11.0.12.
-   Support for Railo has been dropped.
-   Rewrite and config files for IIS and Apache have been removed and has to be added manually instead.
-   The `events/functions.cfm` file has been moved to `global/functions.cfm`.
-   The `models/Model.cfc` file should extend `wheels.Model` instead of `Wheels` (`models/Wheels.cfc` can be deleted).
-   The `controllers/Controller.cfc` file should extend `wheels.Controller` instead of `Wheels`(`controllers/Wheels.cfc` can be deleted).
-   The `init` function of controllers and models should now be named `config` instead.
-   The global setting `modelRequireInit` has been renamed to `modelRequireConfig`.
-   The global setting `cacheControllerInitialization` has been renamed to `cacheControllerConfig`.
-   The global setting `cacheModelInitialization` has been renamed to `cacheModelConfig`.
-   The global setting `clearServerCache` has been renamed to `clearTemplateCache`.
-   The `updateProperties()` method has been removed, use `update()` instead.
-   Form labels automatically generated based on foreign key properties will drop the "Id" from the end (e.g., the label for the "userId" property will be "User", not "User Id").
-   Routes need to be updated to use the new routing system by calling `mapper()`.
-   JavaScript arguments like `confirm` and `disable` have been removed from the link and form helper functions (use the [JS Confirm](https://github.com/perdjurner/cfwheels-js-confirm) and [JS Disable](https://github.com/perdjurner/cfwheels-js-disable) plugins to reinstate the old behaviour).
-   Timestamping (`createdAt`, `updatedAt`) is now in UTC by default (set the global `timeStampMode`setting to `local` to reinstate the old behaviour).
-   Blank strings in SQL are now converted to null checks (e.g. `where="x=''"` becomes `where="x IS NULL"`).
-   Tags are now closed in HTML5 style (e.g. `<img src="x">` instead of `<img src="x" />`).
-   The `encode` argument to `mailTo` now encodes tag content and attributes instead of outputting JavaScript.
-   Class output is now dasherized (e.g. `field-with-errors` instead of `fieldWithErrors`).
-   The `renderPage` function has been renamed to `renderView`.
