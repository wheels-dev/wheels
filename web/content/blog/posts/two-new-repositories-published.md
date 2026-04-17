---
title: Two New Repositories Published
slug: two-new-repositories-published
publishedAt: '2022-06-07T17:47:42.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - Community
  - Documentation
  - Plugin
  - Website
excerpt: >-
  We have published two new repositories named
  cfwheels/cfwheels-www(https://github.com/cfwheels/cfwheels-www) and
  cfwheels/cfwheels-api(https://github.com/cfwheels/cfwheels-api) which handle
  the CFW...
coverImage: null
legacyId: '120'
---
We have published two new repositories named `[cfwheels/cfwheels-www](https://github.com/cfwheels/cfwheels-www)` and `[cfwheels/cfwheels-api](https://github.com/cfwheels/cfwheels-api)` which handle the **_CFWheels.org_** landing page site and the **_api.cfwheels.org_** API documentation site respectively.

The `cfwheels-api` repository is a good example of how you can structure your own projects and keep sensitive information and the core framework files out of your project's source control repository. The project used a `.gitignore` file that keeps these files out of the repo. It also uses a `box.json` file to specify some dependencies to pull the required files back in.

Using dependencies in a `box.json` file is nothing new but what's interesting is that `cfwheels/cfwheels-api` has three dependencies defined. One is the core framework itself and pulls in the latest framework folder. The second is the newly published `CFWheels DotEnvSettings Plugin` which allows keeping sensitive information out of the repository by using a locally defined `.env` file. The last dependency is probably the most interesting, cause that one pulls in the `Semantic Version` module from ForgeBox which is a module that wasn't specifically written for CFWheels but can be pulled in and used none the less. This opens up the potential of using many more modules from ForgeBox instead of being confined to just CFWheels Plugins.
