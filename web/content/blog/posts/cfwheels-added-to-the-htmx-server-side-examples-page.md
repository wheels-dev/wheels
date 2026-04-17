---
title: "CFWheels Added to the htmx Server-Side Examples\_Page"
slug: cfwheels-added-to-the-htmx-server-side-examples-page
publishedAt: '2022-06-17T15:28:09.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - Community
excerpt: >-
  Back in March we published an example app where we took the TodoMVC
  spec(https://github.com/tastejs/todomvc) and built a reference implementation
  of the app with CFWheels and htmx(https://github.co...
coverImage: null
legacyId: '121'
---

Back in March we published an example app where we took the [TodoMVC spec](https://github.com/tastejs/todomvc) and built a reference implementation of the app with [CFWheels and htmx](https://github.com/bpamiri/cfwheels-todomvc-htmx). Here is a quick graphic of the UI of the app.

[![](https://cfwheels.org/blog/wp-content/uploads/2022/03/cfwheels-todomvc-htmx.gif)](https://cfwheels.org/blog/wp-content/uploads/2022/03/cfwheels-todomvc-htmx.gif)

Todo app implemented with CFWheels and htmx

This app has now been added to the list of [Server-Side integration](https://htmx.org/server-examples/) examples on the htmx website.

htmx at it's core is html over the wire. Instead of returning JSON from backend APIs and consuming them with Javascript to build page interactivity, htmx takes a different approach. It expects actual html snippets to be returned that are swapped into the DOM. How it does it, is by extending html with a handful of additional attributes, that probably should have been there in the first place, which enable any HTML element to issue an AJAX call to the backend, specify what triggers the call, and specify how the returned HTML should be added to the DOM.

We'll be doing more with HTMX in the future so it's great to get CFWheels on the radars of the htmx project.
