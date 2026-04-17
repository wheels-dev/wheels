---
title: CFWheels 2.0 Released
slug: cfwheels-2-0-released
publishedAt: '2017-09-30T18:25:08.000Z'
updatedAt: '2025-06-02T13:32:22.000Z'
author: Tom King
tags:
  - 2-0
categories: []
excerpt: >-
  !(https://cfwheels.org/blog/wp-content/uploads/2017/09/cfwheels-20-took-you-long-enough.jpg)(https://cfwheels.org/blog/wp-content/uploads/2017/09/cfwheels-20-took-you-long-enough.jpg)
coverImage: null
legacyId: '93'
---
[![](https://cfwheels.org/blog/wp-content/uploads/2017/09/cfwheels-20-took-you-long-enough.jpg)](https://cfwheels.org/blog/wp-content/uploads/2017/09/cfwheels-20-took-you-long-enough.jpg)

  

Ok, it's been a while, but **finally**, CFWheels 2.0 has gone gold!

1.  Direct Download: [Download zip](https://github.com/cfwheels/cfwheels/releases/download/v2.0.0/cfwheels-2.0.0.zip)
2.  Commandbox quick install : `install cfwheels` (Just downloads and unzips)
3.  Commandbox install wizard via CFWheels CLI (with url rewriting included):  `wheels new` _(make sure your version of the CLI is up to date with_ `_install cfwheels-cli_`_)_

Make sure to check the “Breaking Changes” section, and [please report any bugs](https://github.com/cfwheels/cfwheels/issues). Needless to say, this has been a massive undertaking with over 1000 commits, and over a year in the making. The core team wishes to thank all the many contributors, testers, and well, just users of the framework. We think we're in a pretty strong place to move forward with loads more exciting things in the future. For a comprehensive list of changes, check the [Changelog](https://github.com/cfwheels/cfwheels/blob/master/CHANGELOG.md), but for a quick summary:

1.  New [RESTful routing](https://guides.cfwheels.org/v2.0/docs/routing)
2.  New [Database migration](https://guides.cfwheels.org/v2.0/docs/database-migrations-getting-started) system
3.  New [automatically generating internal documentation](https://guides.cfwheels.org/v2.0/docs/documenting-your-code)
4.  New [Plugin distribution system](https://guides.cfwheels.org/v2.0/docs/installing-and-using-plugins) via CLI and Forgebox
5.  Better [commandbox integration](https://guides.cfwheels.org/v2.0/docs/commandbox) and CLI support
6.  Integrated [CSRF Protection](https://guides.cfwheels.org/v2.0/docs/configuration-and-defaults#csrf-protection-settings)
7.  Vastly [improved Test suite](https://guides.cfwheels.org/v2.0/docs/testing-your-application)
8.  A complete rewrite of the core in cfscript, with javadoc style commenting
9.  And loads more...

Need help upgrading? Check the [upgrade notes](https://guides.cfwheels.org/v2.0/docs/upgrading), and feel free to post questions to the [Google Group](https://groups.google.com/forum/?fromgroups#!forum/cfwheels), or hit us up on the #cfwheels room on the [CFML Slack Channel](http://cfml-slack.herokuapp.com/)
