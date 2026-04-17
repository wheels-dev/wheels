---
title: Wheels CLI matures to Version 1.0
slug: wheels-cli-matures-to-version-1-0
publishedAt: '2022-06-20T07:07:29.000Z'
updatedAt: '2025-05-19T22:32:01.000Z'
author: Peter Amiri
tags: []
categories:
  - CLI
  - Community
  - Releases
excerpt: >-
  It's hard to believe it took so long to get here but modern CFML development
  has come a long way thanks to tools like
  CommandBox(https://www.ortussolutions.com/products/commandbox) and
  ForgeBox(htt...
coverImage: null
legacyId: '122'
---
It's hard to believe it took so long to get here but modern CFML development has come a long way thanks to tools like [CommandBox](https://www.ortussolutions.com/products/commandbox) and [ForgeBox](https://www.forgebox.io). The Wheels CLI is built as a CommandBox module and wouldn't have even been possible without the support of the fine folks at [Ortus Solutions](https://www.ortussolutions.com).

The first commit to the repo for this project was committed back in July of 2016. It's taken a while, that's an understatement, to get here but Wheels itself jumped to 2.0, CommandBox matured, and we were able to put the plumbing in place to support the communication between the CLI and the running server. With nearly 300 commits in the repo, 25 commands in the CLI, and over 20 pages of documentation, it's now time to take the alpha/beta label off send this baby out into the world.

Some of the more notable commands are `wheels new` to use our wizard to start a brand new project. With this command and the corresponding `wheels generate app` command, you can start a new Wheels project in a directory, specify the template to use, pick the CF engine to use, configure the datasource, and setup your reload password. In fact there's a whole host of `generate` commands for every type of object you may want to create. There are a bunch of `dbmigrate` commands to interact with database migrations.

To install the CLI issue the following command:

```
box install cfwheels-cli
```

Don't forget to check out the full [CLI Commands](https://guides.cfwheels.org/cfwheels-guides/command-line-tools/cli-commands) section in the guides too.
