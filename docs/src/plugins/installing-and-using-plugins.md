---
description: Extend Wheels functionality by using plugins.
---

# Installing and Using Plugins

Wheels is a fairly lightweight framework, and we like to keep it that way. We won't be adding thousands of various features to Wheels just because a couple of developers find them "cool." ;)

Our intention is to only have functionality we consider "core" inside of Wheels itself and then encourage the use of _plugins_ for everything else.

By using plugins created by the community or yourself, you're able to add brand new functionality to Wheels or completely change existing features. The possibilities are endless.

### Manually Installing and Uninstalling Plugins

This couldn't be any simpler. To install a plugin, just download the plugin's `zip` file and drop it in the `/app/plugins` folder.

If you want to remove it later simply delete the `zip` file. (Wheels will clean up any leftover folders and files.)

Reloading Wheels is required when installing/uninstalling. (Issue a `reload=true` request.)

### Installing via Commandbox

With the Wheels CLI installed, you can just do:

{% code title="CommandBox" %}
```shell
# List all Wheels plugins on forgebox
$ wheels plugins list
```
{% endcode %}

This will present a list of available plugins. To install one, simply take note of the "Slug" and run with the `install` command.

{% code title="CommandBox" %}
```shell
# install the Shortcodes plugin which has a slug of shortcodes
$ install shortcodes

# install the Select String plugin which has a slug of select-string
$ install select-string
```
{% endcode %}

When run in the root of a Wheels application, it should automatically add the plugin to `/app/plugins` and generate a `.zip` file with the corresponding name and version number.

### File Permissions on plugins Folder

You may need to change access permissions on your application's `/app/plugins` folder so that Wheels can write the subfolders and files that it needs to run. If you get an error when testing out a plugin, you may need to loosen up the permission level.

### Plugin Naming, Versioning, and Dependencies

When you download plugins, you will see that they are named something like this: `Scaffold-0.1.zip`. In this case, `0.1` is the version number of the `Scaffold` plugin. If you drop both `Scaffold-0.1.zip` and `Scaffold-0.2.zip` in the plugins folder, Wheels will use the one with the highest version number and ignore any others.

If you try to install a plugin that is not compatible with your installed version of Wheels or not compatible with a previously installed plugin (i.e., they try to add/override the same functions), Wheels will throw an error on application start.

If you install a plugin that depends on another plugin, you will get a warning message displayed in the debug area. This message will name the plugin that you'll need to download and install to make the originally installed plugin work correctly.

The debug area will also show the version number of the plugin if the plugin Author has included a suitable `box.json` file.

### Due Diligence

Plugins are very powerful, remember, they can completely override other functions, including Wheels core functions and functions of other installed plugins. For this reason we recommend that you take a look at the code itself for the plugins that you intend to use. This is especially important if you have multiple plugins that override the same function. In those cases you'll have to determine if the plugins play well with each other (which they typically do if they run their code and then defer back to the Wheels core function afterwards) or if they clash and cause problems (in which case you can perhaps contribute to the plugin repository in an effort to make the plugins behave better in situations like this).

### Available Plugins

To view all official plugins that are available for Wheels you can go to the [Plugins](https://www.forgebox.io/type/wheels-plugins) listing on forgebox. Often the community will have a better idea of what plugins work best for your situation, so get on the mailing list and ask if you're in any doubt.
