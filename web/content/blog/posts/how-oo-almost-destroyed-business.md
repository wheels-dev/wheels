---
title: How OO Almost Destroyed a Business
slug: how-oo-almost-destroyed-business
publishedAt: '2009-12-24T20:47:50.000Z'
updatedAt: '2025-05-19T22:32:02.000Z'
author: Chris Peters
tags: []
categories:
  - Community
excerpt: >-
  I stumbled across an honest account by Marc Funaro about how OO almost
  destroyed his
  business(http://www.advantexllc.com/blog/post.cfm/how-oo-almost-destroyed-my-business).
  He spares no detail in t...
coverImage: null
legacyId: '33'
---
I stumbled across an honest account by Marc Funaro about [how OO almost destroyed his business](http://www.advantexllc.com/blog/post.cfm/how-oo-almost-destroyed-my-business). He spares no detail in the post, but I still think it is worthwhile to read in its entirety as a reality check for yourself. Dynamic languages like PHP and CFML have been on a quest over the past few years to be more "Java-like," adding more object oriented capabilities. These features bring a lot of promise for your code to become self-documenting and organized. But there have been undercurrents by pragmatists who contest that these features add unnecessary complexity for languages that were "fine just the way they were." As I've progressed through my career with ColdFusion, I've started agreeing more with the pragmatists. While ColdFusion experts have been arguing about "XML versus no-XML" over the past year, I've strongly desired _getting my work done_ so I could feel some accomplishment and have a fresh breath of air away from my computer from time to time. With my personal experience, this is where ColdFusion on Wheels has entered and really brought the fun back into ColdFusion development. One thing that Wheels has done for me is use CFCs to organize my code and make database queries easier. But at the same time, **I don't feel like I'm wasting too much time worrying about the design of my objects**. It all just flows and works organically, and it all works that way simply by following conventions that we've laid out for you. I will forever be amazed at what David Heinemeier Hansson has accomplished by implementing the concepts of Ruby on Rails and what these concepts accomplish for me in my life as a CFML developer through my use of ColdFusion on Wheels. If you at all have felt CFML lose its magic in a way that Marc Funaro described so well, [give Wheels a try](https://cfwheels.org/download). The more you uncover about our framework, the more it _just makes sense_. Our framework considers what ColdFusion as a platform does well and sticks with that. ColdFusion returns recordsets lightning-fast, so Wheels's findAll() methods return recordsets instead of CF's notoriously slow objects. (It also uses objects to represent data when that makes sense.) Wheels also helps you easily understand where your URLs point to in your code with its controller conventions. And hell, I'll even offer up the fact that Wheels's default URL behavior doesn't even give regard to the underlying platform. [Having URLs that end with .cfm, .aspx, .jsp, etc. do nothing to contribute to the overall user experience anyway](http://www.w3.org/Provider/Style/URI "Cool URIs don't  change"). These sentiments bring me a lot of hope for Wheels's role in the CFML community. We're pushing forward and helping you develop beautiful code using _the best_ platform for developing web applications, period.
