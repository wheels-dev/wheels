---
title: Associations Chapter in Documentation
slug: associations-chapter-in-documentation
publishedAt: '2009-12-07T21:01:37.000Z'
updatedAt: '2025-05-19T22:32:18.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  A big part of Wheels's included ORM is its use of associations to describe
  relationships between models. It's been a long time coming, but we released a
  chapter in the Docs about associations(https...
coverImage: null
legacyId: '7'
---
A big part of Wheels's included ORM is its use of _associations_ to describe relationships between models. It's been a long time coming, but we released a [chapter in the Docs about associations](https://cfwheels.org/docs/chapter/associations "Associations") along with the 0.9.1 release of ColdFusion on Wheels. Associations allow you to join data together in dynamic ways without needing to write any SQL. For example, once you define in your models that a user "has many" group memberships, you can make calls like this to obtain a query object containing the user's group memberships:

<cfset user = model("user").findByKey(params.key)> <cfset memberships = user.groupMemberships()>

This is a very small taste of what associations can do for you. Be sure to [read the chapter](https://cfwheels.org/docs/chapter/associations "Associations") to learn all about setting up associations and what's possible.
