---
title: Creating Custom URLs in Your Wheels App with Routes
slug: creating-custom-urls-with-routes
publishedAt: '2008-12-18T21:21:35.000Z'
updatedAt: '2025-05-19T22:32:18.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  Today, I released a chapter in the Documentation(http://www.cfwheels.com/docs)
  called Using Routes(http://www.cfwheels.com/docs/chapter/using-routes). Routes
  are a pretty cool feature of Wheels bec...
coverImage: null
legacyId: '11'
---

Today, I released a chapter in the [Documentation](http://www.cfwheels.com/docs) called [Using Routes](http://www.cfwheels.com/docs/chapter/using-routes). Routes are a pretty cool feature of Wheels because they let you step outside of the URL convention that can sometimes feel like shackles. As I outline in the new chapter, you can create a URL like this: http://www.domain.com /user/johndoe With this line of code in your config/routes.cfm file:

<cfset addRoute(name="userProfile", pattern="user/\[username\]", controller="user", action="profile")>

[Read on](http://www.cfwheels.com/docs/chapter/using-routes) to find out how it all works.
