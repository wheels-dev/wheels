---
title: Testing Plugins on CFWheels 2.x and Travis CI via commandbox
slug: testing-plugins-on-cfwheels-2-x-and-travis-ci-via-commandbox
publishedAt: '2017-05-31T17:25:08.000Z'
updatedAt: '2025-06-02T13:39:04.000Z'
author: Tom King
tags:
  - 2-0
  - plugins
  - travisci
categories: []
excerpt: >-
  One of the nicest things about CFWheels 2.x is the tighter integration with
  command-line tools such as Commandbox. We can take advantage of the new
  testing suite JSON return type and the new CFWhee...
coverImage: null
legacyId: '90'
---
One of the nicest things about CFWheels 2.x is the tighter integration with command-line tools such as Commandbox. We can take advantage of the new testing suite JSON return type and the new CFWheels CLI in Commandbox 2.x to easily build a Travis CI test. It's perhaps easiest to just show the `.travis.yml` file - this goes in the root of your gitHub plugin repository, and once you've turned on testing under Travis.org, will run your test suite on every commit. [https://gist.github.com/neokoenig/504ce0108a1caf0f19d54e87c1a8193c](https://gist.github.com/neokoenig/504ce0108a1caf0f19d54e87c1a8193c) In sum, this:

1.  Installs Commandbox
2.  Installs the CFWheels CLI
3.  Installs the master branch of the CFWheels repository
4.  Installs your plugin from your repository (rather than the forgebox version which will be the version behind)
5.  Starts the local server
6.  Runs the test suite, pointing only at your plugin's unit tests

Naturally, you could do more complex things with this, such as multiple CF Engines, and maybe even multiple CFWheels versions, but for a quick setup it's a good starting point!
