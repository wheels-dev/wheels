---
title: CFWheels Fully Embraces ForgeBox Packages
slug: cfwheels-fully-embraces-forgebox-packages
publishedAt: '2022-04-30T00:13:48.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - CLI
  - Community
  - Documentation
  - Releases
  - Tips &amp; Tricks
excerpt: >-
  As you may know, many years ago CFWheels embraced the distribution of Plugins
  via ForgeBox packages instead of maintaining our own directory. But the
  framework itself remains illusive. There was so...
coverImage: null
legacyId: '113'
---

As you may know, many years ago CFWheels embraced the distribution of Plugins via ForgeBox packages instead of maintaining our own directory. But the framework itself remains illusive. There was some work done in the last few months to put up packages for the framework but those packages were being maintained by hand which made them a show stopper for a long term solution.

Well, thanks to a new CI workflow based on GitHub Actions we now have the building and publishing of the packages fully automated. Giving credit where credit is due, the new workflow borrows heavily from the ColdBox workflow. It used GitHub Actions, Ant, and CommandBox to automate the process.

So what does all this mean for you, let's cut to the chase. This means you can now install a fresh copy of the framework using the following command:

```
box install cfwheels-base-template
```

This will pull down a copy of the latest stable release of the template files and then pull down a copy of the latest stable release of the framework via package dependencies. In fact the CI workflow mentioned about publishes two packages `cfwheels` which is the core framework directory and `cfwheels-base-template` which is all the other files you need to scaffold the framework.

We've even backfilled all the prior released versions of the framework all the way back to version 1.0.0. So you can install a particular version of the framework using the following command:

```
box install cfwheels-base-template@2.0.2
```

In addition you can install the bleeding edge which includes all the work in process towards the next major release using:

```
box install cfwheels-base-template@be
```

And if you ever just need to get a copy of the latest framework files simply use the following command:

```
box install cfwheels
```

All this means that upgrading to a newer version of the framework should be much easier going forward. Frankly you should just need to modify the version of the dependency in the box.json file and issue a `box update` command. But we'll document that more fully when we make our next release.

For now please feel free to play with all this package goodness and let us know if we fumbled anything.
