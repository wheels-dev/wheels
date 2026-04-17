---
title: Moving towards 2.x Beta
slug: moving-towards-2-x-beta
publishedAt: '2017-05-04T16:06:49.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Tom King
tags:
  - 2-0
categories:
  - Documentation
  - Website
excerpt: >-
  It's been a while in the making (probably 9 months or more) but we're finally
  rolling towards a 2.0 beta release, with just a few tickets in the queue left
  before we can set it free on the world. I...
coverImage: null
legacyId: '87'
---

It's been a while in the making (probably 9 months or more) but we're finally rolling towards a 2.0 beta release, with just a few tickets in the queue left before we can set it free on the world. In the meantime, you may have noticed a few changes in the CFWheels ecosystem, which we've needed to do to support CFWheels 2.x properly.

### HTTPS baby!

Firstly, all CFWheels domains are now running over *https://,* which in this day and age, should be a given. No excuses for not doing this now.

### guides.cfwheels.org

"docs.cfwheels.org" has been renamed [guides.cfwheels.org](https://guides.cfwheels.org) and is where the main extended documentation and tutorials will live. This system is based on readme.io, and has been great in quickly creating some nice looking docs. We will continue to add to what's there over the beta launch too. However, it's not perfect: the API reference on there is simply not designed to take something of the scope of the CFWheels API. The page can crash mobile browsers and is a little...unwieldy at best. Adding to the extremely odd SEO of the reference section (i.e, it's not indexed at all), it's time to move it off.

### api.cfwheels.org (alpha)

So as docs.cfwheels.org has been deprecated, we're going to split out the API reference to a new home, [api.cfwheels.org](https://api.cfwheels.org). There's lots of good reasons for this: With CFWheels 2.x, not only has the entire core (well, *almost* the entire core) been moved to cfscript, we've also commented every single public API function with javadoc style comments. This means all the core functions you know and love now have been categorized and commented in the source code, so when pull requests come in, we can keep the documentation up to date at the same time. The 2.x core has a new built in javadoc parser, so now we can just extract a JSON file where we can power api.cfwheels.org. This also has a huge advantage - we can offer offline/built in documentation browsers from within the debug section of your app. It will even read your own functions - so your local documentation reference will be increasingly valuable. More on this in detail soon.

### More to come!

Over the next few weeks, we'll try and get some blog posts out detailing some of the new 2.x beta features in detail. If there's something in particular you'd like to know about, please ping a comment or find us in slack/mailing list/gitHub.
