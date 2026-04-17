---
title: Calling all plugin authors! Time for 2.x...
slug: calling-all-plugin-authors-time-for-2-x-
publishedAt: '2017-05-18T14:32:52.000Z'
updatedAt: '2025-06-02T13:41:32.000Z'
author: Tom King
tags:
  - 2-0
  - plugins
categories: []
excerpt: >-
  With CFWheels 2.0 beta around the corner, it's time to have a cold hard look
  at the CFWheels plugin ecosystem. With 2.x, we've taken the opportunity to
  modernise how we deal with plugins. If you're...
coverImage: null
legacyId: '89'
---
With CFWheels 2.0 beta around the corner, it's time to have a cold hard look at the CFWheels plugin ecosystem. With 2.x, we've taken the opportunity to modernise how we deal with plugins. If you're a plugin author who has previously released something for 1.x, you'll be pleased to hear there aren't that many changes required to get your plugins playing nicely with 2.x, but it's definitely a good time to revisit what you've got out there.

### Introducing Forgebox.io

One of the main problems we had previously was a lack of a centralised repository of CFwheels plugins. The old system relied on a bit too much manual updating, and over time got a little long in the tooth. So now, all plugins should be added to [forgebox.io](https://www.forgebox.io/type/cfwheels-plugins), specifically in the `CFWheels Plugins` category. If you [go and have a look now](https://www.forgebox.io/type/cfwheels-plugins), you'll see a few added by the core team as examples. Adding your plugin shouldn't be too much hard work, but it's definitely worth setting yourself up properly to publish to forgebox automatically via the commandline. There's an extensive tutorial over at [guides.cfwheels.org](https://guides.cfwheels.org/v2.0/docs/publishing-plugins) which we recommend you follow. In short, you ideally need a properly configured `box.json` file and for your plugins to use git tagged releases (ideally). If you've not installed [commandbox](https://www.ortussolutions.com/products/commandbox) and the [CFWheels CLI](https://guides.cfwheels.org/v2.0/docs/commandbox), now is definitely the time to try it!

### Easier for other developers too

Once your plugin is in the forgebox system, other CFWheels users can install your plugin with a single CLI command: `install slugName`; If they've got the CFWheels CLI installed, it will automatically create appropriate `.zip` files with the correct version number (which you'll have set in `box.json`) too. They'll also be able to view all existing plugins with `wheels plugins list`  making it extra quick to find the plugin they need. Dependencies are then tracked in that user's `box.json` file, so they can even distribute an app without your plugin, and then simply run `install` to go and download the correct version later: they can even update to the latest version of your plugin via the CLI too, or freeze it to a specific version.

### Automatic Java Mappings

One of the nice new features of 2.x is the automatic java library mappings which plugins can now take advantage of. Previously, you had to rely on the developer to manually add an entry into `this.javaSettings.loadpaths` if your plugin required use of a `.class` or `.jar` file. Now, we scan the plugin folders on startup, and automatically add any folders which contain `.jar` or `.class` files. One less step for configuration! You can see an example of this in the [CFWheels bCrypt](https://www.forgebox.io/view/cfwheels-bcrypt) plugin, which adds a quick wrapper around the bCrypt java class.

### Don't forget your comments!

In a previous post, we talked about the new embedded documentation: plugins can now take advantage of this. For plugin authors, we're recommending you comment all public functions - here's a quasi code example below. [https://gist.github.com/neokoenig/d149a75aa69b8cac49464ffc12f19027](https://gist.github.com/neokoenig/d149a75aa69b8cac49464ffc12f19027) The important part is the `[section: Plugins]` and `[category: Plugin Name]` part, which will automatically sort your functions in the correct place in the internal documentation. It's a good habit to get into, and will help other users of your plugin too.

### Oh, and unit tests :)

Don't forget to write some unit tests too (hey, don't we all do TDD?); there's been some changes to the test suite in 2.x, and writing unit tests is loads easier. More to follow on:

1.  New functions for testing in 2.x
2.  Running plugin tests via command line,
3.  How to add your plugin to Travis CI for continuous integration testing
