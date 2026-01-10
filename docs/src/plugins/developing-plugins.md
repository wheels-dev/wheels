---
description: Extend Wheels functionality by creating a plugin.
---

# Developing Plugins

Plugins are the recommended way to get new code accepted into Wheels. If you have written code that you think constitutes core functionality and should be added to Wheels, please create a plugin. After the community has used it for a while, it will be a simple task for us to integrate it into the Wheels core.

To create a plugin named `MyPlugin`, you will need to create a `MyPlugin.cfc` and an `index.cfm` file. Then zip these together as `MyPlugin-x.x.zip`, where `x.x` is the version number of your plugin.

The only other requirement to make a plugin work is that `MyPlugin.cfc` must contain a method named `init`. This method must set a variable called `this.version`, specifying the Wheels version the plugin is meant to be used on (or several Wheels version numbers in a list) and then return itself.

Here's an example:

{% code title="ExamplePlugin.cfc" %}
```javascript
component {
  function init(){
    this.version="1.4.5,2.0";
    return this;
  }
}
```
{% endcode %}

{% hint style="info" %}
#### Init() not config()

Note that plugins still use `init()` rather than `config()`
{% endhint %}

The `index.cfm` file is the user interface for your plugin and will be viewable when clicking through to it from the debug area of your application.

### Using a Plugin to Add or Alter Capabilities

A plugin can add brand new functions to Wheels or override existing ones. A plugin can also have a simple one-page user interface so that the users of the plugin can provide input, display content, etc.

To add or override a function, you simply add the function to `MyPlugin.cfc`, and Wheels will inject it into Wheels on application start.

Please note that all functions in your plugin need to be public `(access="public")`. If you have functions that should only be called from the plugin itself, we recommend starting the function name with the `$`character (this is how many internal Wheels functions are named as well) to avoid any naming collisions.

It is also important to note that although you can overwrite functions, they are still available for you to leverage with the use of `core.functionName()`.

### Example: Overriding timeAgoInWords()

Let's say that we wanted Wheels's built-in function [timeAgoInWords()](https://wheels.dev/api/v3.0.0/controller.timeAgoInWords.html) to return the time followed by the string " (approximately)":

{% code title="timeAgoInWords.cfc" %}
```javascript
public string function timeAgoInWords(){
  return core.timeAgoInWords(argumentCollection=arguments) & " (approximately)";
}
```
{% endcode %}

### Plugin Attributes

There are 3 attributes you can set on your plugin to customize its behavior. The first and most important one is the `mixin` attribute.

By default, the functions in your plugins will be injected into all Wheels objects (controller, model, etc.). This is usually not necessary, and to avoid this overhead, you can use the mixin attribute to specify exactly where the functions should be injected. If you have a function that should be available in a controller (or view) this is how it could look:

```markup
<cfcomponent output="false" mixin="controller">
```

The `mixin` attribute can be set either on the `cfcomponent` tag or on the individual `cffunction` tags.

The following values can be used for the mixin attribute: `application, global, none, controller, model, dispatch, microsoftsqlserver, mysql, oracle, postgresql`.

Another useful attribute is the `environment` attribute. Using this, you can tell Wheels that a plugin should only inject its functions in certain environment modes. Here's an example of that, taken from the Scaffold plugin, which doesn't need to inject any functions to Wheels at all when it's running in production mode.

```markup
<cfcomponent output="false" mixin="controller" environment="development">
```

Finally, there is a way to specify that your plugin needs another plugin installed in order to work. Here's an example of that:

```markup
<cfcomponent output="false" dependency="someOtherPlugin">
```

### Making Plugin Development More Convenient with Wheels Settings

When your Wheels application first initializes, it will unzip and cache the zip files in the `/plugins` folder. Each plugin then has its own expanded subfolder. If a subfolder exists but has no corresponding zip file, Wheels will delete the folder and its contents.

This is convenient when you're deploying plugins but can be annoying when you're developing your own plugins. By default, every time you make a change to your plugin, you need to rezip your plugin files and reload the Wheels application by adding `?reload=true` to the URL.

### Disabling Plugin Overwriting

To force Wheels to skip the unzipping process, set the `overwritePlugins` setting to `false` in the development environment.

{% code title="/config/development/settings.cfm" %}
```javascript
set(overwritePlugins=false);
```
{% endcode %}

With this setting, you'll be able to reload your application without worrying about your file being overwritten by the contents of the corresponding zip file.

### Disabling Plugin Folder Deletion

To force Wheels to skip the folder deletion process, set the `deletePluginDirectories` setting to `false` for your `development` environment.

{% code title="/config/development/settings.cfm" %}
```javascript
set(deletePluginDirectories=false);
```
{% endcode %}

With this setting, you can now develop new plugins in your application without worrying about having a corresponding zip file in place.

See the chapter on [Configuration and Defaults](https://wheels.dev/3.0.0/guides/working-with-wheels/configuration-and-defaults) for more details about changing Wheels settings.

### Stand-Alone Plugins

If your plugin is completely stand-alone, you can call it from its view page using just the name of the plugin. This works because Wheels has created a pointer to the plugin object residing in the `application scope`. One example of a stand-alone plugin is the PluginManager. If you check out its view code, you will see that it calls itself like this:

```javascript
pluginManager.installPlugin(URL.plugin);
```

### Don't forget to comment!

With Wheels 2.x we can take advantage of the inbuilt documentation generator. Try and tag your public facing functions appropriately.

Here's an example from the wheels ical4J plugin:

{% code title="ical4J" %}
```java
/**
 * Given a iCal style repeat rule, a seed date and a from-to range, get all recurring dates which satisfy those conditions
 *
 * [section: Plugins]
 * [category: Calendaring]
 *
 * @pattern The ical RRULE style string
 * @seed The seed date
 * @from When to generate repeat range from
 * @to When to generate repeat range till
 */
public array function getRecurringDates(
 required string pattern,
 required date seed,
 date from,
 date to
){
    local.recur = $ical_createRecur(arguments.pattern);
    return local.recur.getDates($ical_createDate(arguments.seed), $ical_createDate(arguments.from), $ical_createDate(arguments.to), $ical_createValue("DATE"));
}
```
{% endcode %}

The javaDoc style comments will automatically show this function under Plugins > Calendaring, rather than in the "Uncategorized" functions. The `@parameter` lines give a helpful hint to the user

### Box.json

With `2.x`, a `box.json` is required for new plugins. Read the [Publishing Plugins](https://wheels.dev/3.0.0/guides/plugins/publishing-plugins) chapter for more details on that. One advantage is that Wheels now includes the version and meta data for each plugin when there's a `box.json` file.

```javascript
// Version Number
application.wheels.pluginMeta["pluginName"]["version"];

// Meta Struct from box.json
application.wheels.pluginMeta["pluginName"]["boxjson"];
```

This saves you having to read in the `box.json` file, should you wish to use it for storing ancillary data and settings.

### Automatic Java Lib Mappings

If you've ever wanted to do a quick wrapper for a java class/lib, this new feature in `2.x` means you can add a `.class` or `.jar` file, and it will be automatically mapped into the `this.javaSettings.loadpaths` setting when the application starts.

This means you can distribute plugins with Java libs and they'll work properly without additional user intervention!

### Enabling Travis CI Testing

One of the nicest things about `2.x` is the tighter integration with command-line tools such as CommandBox. We can take advantage of the new testing suite JSON return type and the new Wheels CLI in CommandBox 2.x to easily build a Travis CI test. It's perhaps easiest to just show the `.travis.yml` file - this goes in the root of your gitHub plugin repository, and once you've turned on testing under Travis.org, will run your test suite on every commit.

{% code title=".travis.yml" %}
```yaml
language: java
sudo: required
jdk:
  - oraclejdk8
before_install:
  # Get Commandbox
  - sudo apt-key adv --keyserver keys.gnupg.net --recv 6DA70622
  - sudo echo "deb http://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
install:
  # Install Commandbox
  - sudo apt-get update && sudo apt-get --assume-yes install CommandBox
  # Check it's working
  - box version
  # Install CLI: needed to repackage the plugin to a zip on install
  - box install wheels-cli
  # Install Master Branch; nb, installed into folder of the git repo name, i.e neokoenig/wheels-ical4j
  - box install wheels-dev/wheels
  # Install the Plugin: use gitHub path to get the absolute latest rather than the forgebox version
  - box install neokoenig/wheels-ical4j
before_script:
  # Master branch has a bunch of server.jsons we can use: lucee4 | lucee5 | cf10 | cf11 | cf2016
  - box server start lucee5
# Type should be the name of the plugin | servername should reflect the server we've just started
script: >
  testResults="$(box wheels test type=ical4j servername=lucee5)";
  echo "$testResults";
  if ! grep -i "\Tests Complete: All Good!" <<< $testResults;  then exit 1; fi
notifications:
    email: true
```
{% endcode %}

In sum, this:

* Installs CommandBox
* Installs the Wheels CLI
* Installs the master branch of the Wheels repository
* Installs your plugin from your repository (rather than the forgebox version which will be the version behind)
* Starts the local server
* Runs the test suite, pointing only at your plugin's unit tests

Naturally, you could do more complex things with this, such as multiple CF Engines, but for a quick setup it's a good starting point!

### Now Go Build Some Plugins!

Armed with this knowledge about plugins, you can now go and add that feature you've always wanted or change that behavior you've always hated. We've stripped you of any right to blame us for your discontents. :)
