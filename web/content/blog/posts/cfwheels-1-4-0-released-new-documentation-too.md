---
title: 'CFWheels 1.4.0 released, New documentation too..'
slug: cfwheels-1-4-0-released-new-documentation-too
publishedAt: '2015-05-08T17:45:32.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 1-4
categories:
  - Releases
  - Website
excerpt: 'First, some new announcements'
coverImage: null
legacyId: '80'
---
### First, some new announcements

You may have noticed a few changes around here! With the release of 1.4, we've taken the opportunity to greatly simplify our web footprint.

-   **All documentation** now lives on [http://docs.cfwheels.org/](http://docs.cfwheels.org/) (thanks to readme.io). We hope this will allow people to more easily contribute to the fantastic documentation already there; you need a (free) readme.io account, but you should be able to 'suggest edits' for any page - feel free to help us out! We're in the process of adding redirects from the old documentation - please bear with us on this one.
-   You'll notice the **plugin listings** are greatly simplified - this is a temporary measure whilst we look at the whole plugin ecosystem generally
-   **Downloads** now live on the readme.io site at [http://docs.cfwheels.org/page/download](http://docs.cfwheels.org/page/download), but don't forget you can always get everything at the [Git Repo](https://github.com/cfwheels/cfwheels/releases)
-   You'll notice a small change in the cfWheels logo - don't panic, you're not going mad, we just thought it might be nice to have something new and shiny to look at.
-   [Tom King](http://www.oxalto.co.uk) and [Tim Badolato](https://github.com/timsayshey) are now part of the Wheels core team. "Per" still does all the actual real work :)

### Onwards and upwards!

1.4 is released, which brings the usual host of fixes and improvements, most noticeably a few tweaks to get Wheels running with [Lucee Server](http://luc.ee): CFWheels should now correctly identify itself as Lucee in the debug output, and various other (older) Railo specific tweaks should get applied. Note, if you're ever testing for 'railo' in the server scope on Lucee, it will return as true. A couple of other changes might catch you out too, noticeably removal of the h() function, and "development" now being the default environment mode. [Get 1.4 Now!](http://docs.cfwheels.org/v1.4/page/download) **Upgrading from 1.3x**

-   Replace the entire /wheels/ folder
-   Replace URL rewriting rule files - i.e, /.htaccess, /web.config, /IsapiRewrite4.ini

Release notes:

**Model Enhancements**

-   Allow spaces in list passed in to the "include" argument on finders - [#150](https://github.com/cfwheels/cfwheels/issues/150) \[Per Djurner\]
-   Added findOrCreateByProperty, findAllKeys(), findFirst() and findLast() finder methods - \[Per Djurner\]
-   Add support for "GROUP BY" in sum(), average() etc. - [#464](https://github.com/cfwheels/cfwheels/issues/464) \[Per Djurner\]
-   Made exists() check for any record when "key" and "where" is not passed in \[Per Djurner\]
-   Added clearChangeInformation() for clearing knowledge of object changes - [#433](https://github.com/cfwheels/cfwheels/issues/433) \[Jeremy Keczan, Per Djurner\]
-   Evaluate validation error messages at runtime - [#470](https://github.com/cfwheels/cfwheels/issues/470) \[Per Djurner\]

**View Enhancements**

-   Respect blank "text" argument in linkTo() - [#365](https://github.com/cfwheels/cfwheels/issues/365) \[Adam Chapman, Tony Petruzzi, Per Djurner\]
-   Allow styleSheetLinkTag() and JavaScriptIncludeTag() to reference files starting from the root - \[Per Djurner\]
-   Added "monthNames" and "monthAbbreviations" arguments to form helpers for easy localization - \[Per Djurner\]

**Controller Enhancements**

-   Ability to prepend functions to the filter chain instead of appending - [#321](https://github.com/cfwheels/cfwheels/issues/321) \[Per Djurner\]
-   Pass in "appendToKey" to caches() to cache content separately - [#439](https://github.com/cfwheels/cfwheels/issues/439) \[Per Djurner\]
-   Allow external attachments with sendEmail() - \[Adam Chapman, Tony Petruzzi\]
-   Ability to redirect to a specific URL - \[Simon Allard\]
-   Option to correct JSON output by passing in x="string" or x="integer" to renderWith() - \[Per Djurner\]

**Bug Fixes**

-   Fix for blank path\_info in CGI scope - [#447](https://github.com/cfwheels/cfwheels/issues/447) \[Tim Badolato, Tony Petruzzi, Per Djurner\]
-   Fix for accessing request scope key that does not exist from session - [#446](https://github.com/cfwheels/cfwheels/issues/446) \[Brent Alexander, Per Djurner\]
-   Removed "validate" property that was incorrectly set when calling create() - \[Per Djurner\]
-   Pass through "parameterize" in exists() \[Per Djurner\]
-   Do not remove "AS" when it's in the SQL for a calculated property - [#453](https://github.com/cfwheels/cfwheels/issues/453) \[Jean Duteau, Per Djurner\]
-   Obfuscate parameters in named route patterns when URL rewriting is off - [#455](https://github.com/cfwheels/cfwheels/issues/455) \[Amber Cline, Per Djurner\]
-   Pass through "includeSoftDeletes" argument correctly - [#451](https://github.com/cfwheels/cfwheels/issues/451) \[Jon Brose\]

**Miscellaneous**

-   Support for the Lucee server - \[Tom King\]
-   Made "development" the default environment mode - \[Per Djurner\]
-   Removed deprecation work-around for the "if" argument on validation helpers - \[Per Djurner\]
-   Removed deprecation work-around for the "class" argument on association initialization methods - \[Per Djurner\]
-   Removed the "lib" folder - \[Per Djurner\]
-   Removed the h() function, use XMLFormat() instead - \[Per Djurner\]
