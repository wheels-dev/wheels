---
title: 'The Release Candidate Is Out: Wheels 1.0 RC1'
slug: release-candidate-1-0-rc1
publishedAt: '2009-12-02T10:21:57.000Z'
updatedAt: '2025-05-19T22:32:18.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  We've been
  talking(https://cfwheels.org/blog/index.cfm/2008/10/28/Wheels-083-Our-Final-Beta-Release
  "Wheels 0.8.3: Our Final Beta Release?")
  about(https://cfwheels.org/blog/index.cfm/2009/3/4/Wheel...
coverImage: null
legacyId: '4'
---
We've been [talking](https://cfwheels.org/blog/index.cfm/2008/10/28/Wheels-083-Our-Final-Beta-Release "Wheels 0.8.3: Our Final Beta Release?") [about](https://cfwheels.org/blog/index.cfm/2009/3/4/Wheels-09-The-Final-Final-Beta-Cycle "Wheels 0.9: The Final Final Beta Cycle") getting to 1.0 for quite some time now, and the first release candidate is here. [Download ColdFusion on Wheels 1.0 RC1](https://cfwheels.org/download)

## New Features

We have focused primarily on getting Wheels stable and ready for a solid 1.0 release, so there aren't that many new features this time around. But we couldn't help but add a few exciting things though, like support for URL rewriting in IIS 7 and in subfolders when using Apache, to name a couple. We've also improved our plugin system a little, which has lead to a lot of new great [plugins](https://cfwheels.org/plugins) popping up on the Google Group and on the site.

## Important Bug Fixes

With the help of everyone in the Google Group, we have fixed between 20-30 bugs since we released 0.9.4. Thanks everyone! One bug fix worth pointing out is that we were able to work around a mapping bug in Railo that caused pages to load slowly. So if you're using Wheels on Railo you will see much faster load times after upgrading. You can view the full list of new features and bug fixes in the change log included in the download file.

## How to Upgrade

As usual, the easiest way to upgrade is to setup an empty website, deploy a fresh copy of Wheels, and then transfer your old application code to it. If you'd rather upgrade directly to an existing folder, here are the required steps:

1.  Replace the wheels folder, all files in the root, and the views/wheels folder with files from the 1.0 zip.
2.  Add/overwrite Wheels.cfc in the models folder.
3.  Add/overwrite Wheels.cfc in the controllers folder.
4.  Change the "extends" attribute in controllers/Controller.cfc to "Wheels".
5.  Change the "extends" attribute in models/Model.cfc to "Wheels".

We'll be focusing on fixing any remaining bugs, continuing to unit test the API, finishing documentation, and testing plugins. Thanks everyone for your support. This framework has a bright future, and it's all because of this amazing community.
