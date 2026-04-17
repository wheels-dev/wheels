---
title: Starting a New CFWheels Project with the CLI
slug: starting-a-new-cfwheels-project-with-the-cli
publishedAt: '2022-03-24T20:29:11.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags:
  - cli
  - tutorial
categories:
  - CLI
  - Tips &amp; Tricks
  - Tutorials
excerpt: >-
  !(https://cfwheels.org/blog/wp-content/uploads/2022/03/wheels-generate-app-larger.gif)(https://cfwheels.org/blog/wp-content/uploads/2022/03/wheels-generate-app-larger.gif)
coverImage: null
legacyId: '108'
---
[![](https://cfwheels.org/blog/wp-content/uploads/2022/03/wheels-generate-app-larger.gif)](https://cfwheels.org/blog/wp-content/uploads/2022/03/wheels-generate-app-larger.gif)

If you're not using CommandBox for your CFWheels development, you're in for a treat. This is a quick post to show case how easy it is to start a new CFWheels project with the help of the the `wheels` command for CommandBox.

If you have CommandBox installed and have the `cfwheels-cli` module installed, then simply launch CommandBox by typing `box` and then issue the command `wheels generate app myApp` . This simple command will take care of the following:

-   Create a folder in the current working directory for the project and name if **myApp**
-   Copy the `cfwheels-template-base` package from ForgeBox and expand it in the root of the myApp folder
-   Copy the `cfwheels-core` package from ForgeBox and expand it into the wheels folder in the root of the myApp folder
-   This command also takes care of naming your app **myApp** or whatever name you pass in

You may be asking yourself, what are all these packages you're talking about? Well, we are starting to use the package management system provided by ForgeBox and CommandBox to make distribution of sample apps easier as well as installing and updating projects based on CFWheels. More to come on these topics later but this is just to whet your appetite.
