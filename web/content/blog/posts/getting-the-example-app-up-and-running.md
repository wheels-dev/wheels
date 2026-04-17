---
title: Getting the Example App Up and Running
slug: getting-the-example-app-up-and-running
publishedAt: '2022-03-30T22:03:00.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - Community
excerpt: >-
  Have you looked at the CFWheels Example App lately? If you're wondering, wait,
  there is an example app?, you're not alone. Tom has done a great job putting
  the CFWheels Example App together but his...
coverImage: null
legacyId: '111'
---
Have you looked at the CFWheels Example App lately? If you're wondering, wait, there is an example app?, you're not alone. Tom has done a great job putting the CFWheels Example App together but historically getting it up and running was somewhat difficult. It requires a database to be setup, a datasource to be defined, and migrations to be run.

With the help of our new templating structure and some improvements to the CFWheels-CLI commands, getting the Example application is a piece of cake. All you need to do is issue three commands inside a CommandBox shell and the app magically opens up in your browser.

So lets get started:

```
wheels g app name=example datasourceName=exampleh2 template=cfwheels-template-example-app --setupH2
package install
server start
```

So what do those commands do for us. The first line is the longhand way to install a fresh CFWheels app using one of the published templates from Forgbox.io. This command gives the application a name, sets up a datasource, and configures it to use the built in H2 database in the Lucee CF Engine. (Are you wondering, wait, Lucee has a built in database engine?) The next line installs all our development and production dependencies into our application directory. Lastly we start the Lucee server and the application launches in our default browser.

You'll initially see the installation verification screen.

[![](https://cfwheels.org/blog/wp-content/uploads/2022/03/Screen-Shot-2022-03-30-at-11.48.06-AM-1024x614.png)](https://cfwheels.org/blog/wp-content/uploads/2022/03/Screen-Shot-2022-03-30-at-11.48.06-AM.png)

Once you click on the Reload button, the application will reload and launch the Example App.

[![](/blog-images/d182f0d5f176.png)](https://cfwheels.org/blog/wp-content/uploads/2022/03/Screen-Shot-2022-03-30-at-11.49.16-AM.png)

At this point you can login using one of the default user ID listed below.

```
user: admin@domain.com
user: editor@domain.com
user: user@domain.com
user: user2@domain.com
user: user3@domain.com (Pending Verification)
```

All of them have the password set to `Password123!`

I hope you enjoy playing with this Example App and it serves as a learning tool as it was intended. Please share your experience in the comments below.

EDIT: The Lucee server that starts up will have `cfwheels` set as its admin password.
