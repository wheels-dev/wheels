---
title: TodoMVC Implementation with CFWheels and HTMX
slug: todomvc-implementation-with-cfwheels-and-htmx
publishedAt: '2022-03-29T21:31:33.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - Community
  - Tips &amp; Tricks
  - Tutorials
excerpt: >-
  Recently I've been playing around with HTMX and really starting to love it. So
  what is HTMX? From their website(https://htmx.org):
coverImage: null
legacyId: '110'
---

Recently I've been playing around with HTMX and really starting to love it. So what is HTMX? From their [website](https://htmx.org):

> htmx gives you access to  [AJAX](https://htmx.org/docs#ajax), [CSS Transitions](https://htmx.org/docs#css_transitions),  [WebSockets](https://htmx.org/docs#websockets) and [Server Sent Events](https://htmx.org/docs#sse) directly in HTML, using [attributes](https://htmx.org/reference#attributes), so you can build [modern user interfaces](https://htmx.org/examples) with the [simplicity](https://en.wikipedia.org/wiki/HATEOAS) and [power](https://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm) of hypertext
>
> Introduction to htmx

And also:

> Why should only [`<a>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a) and [`<form>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form) be able to make HTTP requests?  
> Why should only [`click`](https://developer.mozilla.org/en-US/docs/Web/API/Element/click_event) & [`submit`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit_event) events trigger them?  
> Why should only [`GET`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET) & [`POST`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST) methods be [available](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)?  
> Why should you only be able to replace the **entire** screen?
>
> By removing these arbitrary constraints, htmx completes HTML as a [hypertext](https://en.wikipedia.org/wiki/Hypertext)
>
> Motivation behind htmx

So what does this all mean? Well, in its simplest form, it means being able to build modern web applications with the UX that users have come to expect, with the HTML, CSS, and the backend technology of your choice which in our case is CFML and CFWheels.

So I decide to see if I could build the [TodoMVC](https://todomvc.com) project using no hand written JavaScript and only relying on HTML, CSS, and CFWheels. I downloaded the template project and took a look at the application specs to get an idea of what to implement.

Here is the video of the running app:

[![](https://cfwheels.org/blog/wp-content/uploads/2022/03/cfwheels-todomvc-htmx.gif)](https://cfwheels.org/blog/wp-content/uploads/2022/03/cfwheels-todomvc-htmx.gif)

So if you want to run the app locally, you'll need to have Commandbox installed and the CFWHeels CLI commands for CommandBox installed as well. With those two items taken care of, launch a CommandBox and issue the following commands.

```
wheels g app name=todo datasourceName=todo template=cfwheels-todomvc-htmx --setupH2
package install
server start
```

Let's look at those lines and talk about what they do. The first line `wheels g app` will download the template app from Forgbox.io and create a CFWheels application and name it `todo`. It also create a H2 database and configures the datasource for you. The next line will `install` all the dependencies of our app. These include, a few CommandBox modules to make development easier, the CFWheels core framework directory and place it into the `wheels` folder, and install the H2 drivers into our Lucee server for out application. The last line will `start` our Lucee server. I've also added a setting to automatically run the Database migrations on application startup so the database schema is created.

You can checkout the code on [GitHub](https://github.com/bpamiri/cfwheels-todomvc-htmx). Let me know what you think.

EDIT: The Lucee server that starts up will have `cfwheels` set as its admin password.
