---
description: >-
  An overview of Wheels configuration and how is it used in your applications.
  Learn how to override a Wheels convention to make it your own.
---

# Configuration and Defaults

We all love the "Convention over Configuration" motto of Wheels, but what about those two cases that pop into everyone's head? _What if I want to develop in my own way?_ Or, _What about an existing application that I need to port into Wheels?_ Gladly, that's what configuration and defaults are there for. Let's take a look at exactly how this is performed.

### Where Configurations Happen

You will find configuration files in the `config` folder of your Wheels application. In general, most of your settings will go in `config/settings.cfm`.

You can also set values based on what environment you have set. For example, you can have different values for your settings depending on whether you're in `development` mode or `production` mode. See the chapter on [Switching Environments](switching-environments.md) for more details.

### How to Set Configurations

To change a Wheels application default, you generally use the [set()](https://wheels.dev/api/v3.0.0/controller.set.html) function. With it, you can perform all sorts of tweaks to the framework's default behaviors.

### How to Access Configuration Values

Use the [get()](https://wheels.dev/api/v3.0.0/controller.get.html) function to access the value of a Wheels application setting. Just pass it the name of the setting.



{% code title="CFScript" %}
```javascript
if (get("environment") == "production") {
    // Do something for production environment
}
```
{% endcode %}

### Setting CFML Application Configurations

In CFML's standard `Application.cfc`, you can normally set values for your application's properties in the `this`scope. Wheels still provides these options to you in the file at `config/app.cfm`.

Here is an example of what can go in `config/app.cfm`:

{% code title="config/app.cfm" %}
```javascript
this.name = "TheNextSiteToBeatTwitter";
this.sessionManagement = false;

this.customTagPaths = ListAppend(
  this.customTagPaths,
  ExpandPath("../customtags")
);
```
{% endcode %}

### Types of Configurations Available

There are several types of configurations that you can perform in Wheels to override all those default behaviors. In Wheels, you can find all these configuration options:

* [Environment settings](configuration-and-defaults.md#environment-settings)
* [URL rewriting settings](configuration-and-defaults.md#url-rewriting-settings)
* [Data source settings](configuration-and-defaults.md#data-source-settings)
* [Function settings](configuration-and-defaults.md#function-settings)
* [Debugging and error settings](configuration-and-defaults.md#debugging-and-error-settings)
* [Caching settings](configuration-and-defaults.md#caching-settings)
* [ORM settings](configuration-and-defaults.md#orm-settings)
* [Plugin settings](configuration-and-defaults.md#plugin-settings)
* [Media settings](configuration-and-defaults.md#media-settings)
* [Routing settings](configuration-and-defaults.md#routing-settings)
* [View helper settings](configuration-and-defaults.md#view-helper-settings)
* [CSRF protection settings](configuration-and-defaults.md#csrf-protection-settings)
* [Miscellaneous Settings](configuration-and-defaults.md#miscellaneous-settings)
* [Migrator settings](configuration-and-defaults.md#migrator-configuration-settings)

Let's take a closer look at each of these options.

### Environment Settings

Not only are the environments useful for separating your production settings from your "under development" settings, but they are also opportunities for you to override settings that will only take effect in a specified environment.

The setting for the current environment can be found in `app/config/environment.cfm` and should look something like this:

{% code title="app/config/environment.cfm" %}
```javascript
set(environment="development");
```
{% endcode %}

**Full Listing of Environment Settings**

| Name                         | Type    | Default                               | Description                                                                                                                                                                                                                                  |
| ---------------------------- | ------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| environment                  | string  | development                           | Environment to load. Set this value in app/config/environment.cfm. Valid values are development, testing, maintenance, and production.                                                                                                       |
| reloadPassword               | string  | \[empty string]                       | Password to require when reloading the Wheels application from the URL. Leave empty to require no password.                                                                                                                                |
| redirectAfterReload          | boolean | Enabled in maintenance and production | Whether or not to redirect away from the current URL when it includes a reload request. This hinders accidentally exposing your application's reload URL and password in web analytics software, screenshots of the browser, etc.            |
| ipExceptions                 | string  | \[empty string]                       | IP addresses that Wheels will ignore when the environment is set to maintenance. That way administrators can test the site while in maintenance mode, while the rest of users will see the message loaded in app/events/onmaintenance.cfm. |
| allowEnvironmentSwitchViaUrl | boolean | true                                  | Set to false to disable switching of environment configurations via URL. You can still reload the application, but switching environments themselves will be disabled.                                                                       |

### URL Rewriting Settings

Sometimes it is useful for our applications to "force" URL rewriting. By default, Wheels will try to determine what type of URL rewriting to perform and set it up for you. But you can force in or out this setting by using the example below:

{% code title="CFScript" %}
```javascript
set(urlRewriting="Off");
```
{% endcode %}

The code above will tell Wheels to skip its automatic detection of the URL Rewriting capabilities and just set it as `"Off"`.

You can also set it to "Partial" if you believe that your web server is capable of rewriting the URL as folders after `index.cfm`.

For more information, read the chapter about [URL Rewriting](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/url-rewriting).

### Data Source Settings

Probably the most important configuration of them all. What is an application without a database to store all of its precious data?

The data source configuration is what tells Wheels which database to use for all of its models. (This can be overridden on a per-model basis, but that will be covered later.) To set this up in Wheels, it's just as easy as the previous example:

{% code title="CFScript" %}
```javascript
set(dataSourceName="yourDataSourceName");
set(dataSourceUserName="yourDataSourceUsername");
set(dataSourcePassword="yourDataSourcePassword");
```
{% endcode %}

### Function Settings

OK, here it's where the fun begins! Wheels includes a lot of functions to make your life as a CFML developer easier. A lot of those functions have sensible default argument values to minimize the amount of code that you need to write. And yes, you guessed it, Wheels lets you override those default argument values application-wide.

Let's look at a little of example:

{% code title="CFScript" %}
```javascript
set(functionName="findAll", perPage=20);
```
{% endcode %}

That little line of code will make all calls to the [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) method in Wheels return a maximum number of 20 record per page (if pagination is enabled for that [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) call). How great is that? You don't need to set the `perPage` value for every single call to [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) if you have a different requirement than the Wheels default of 10 records.

### Debugging and Error Settings

You'll generally want to configure how Wheels handles errors and debugging information based on your environment. For example, you probably won't want to expose CFML errors in your production environment, whereas you would want to see those errors in your development environment.

For example, let's say that we want to enable debugging information in our "development" environment temporarily:

{% code title="CFScript" %}
```javascript
// /config/development/settings.cfm
set(showDebugInformation=false);
```
{% endcode %}

**Full Listing of Debugging and Error Settings**

| Name                  | Type    | Default                                                                  | Description                                                                                                                                                                         |
| --------------------- | ------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| errorEmailServer      | string  | \[empty string]                                                          | Server to use to send out error emails. When left blank, this defaults to settings in the ColdFusion Administrator (if set).                                                        |
| errorEmailAddress     | string  | \[empty string]                                                          | Comma-delimited list of email address to send error notifications to. Only applies if sendEmailOnError is set to true.                                                              |
| errorEmailSubject     | string  | Error                                                                    | Subject of email that gets sent to administrators on errors. Only applies if sendEmailOnError is set to true.                                                                       |
| excludeFromErrorEmail | string  | \[empty string]                                                          | List of variables available in the scopes to exclude from the scope dumps included in error emails. Use this to keep sensitive information from being sent in plain text over email.     |
| sendEmailOnError      | boolean | Enabled in production environments that have a TLD like .com, .org, etc. | When set to true, Wheels will send an email to administrators whenever Wheels throws an error.                                                                                  |
| showDebugInformation  | boolean | Enabled in development mode.                                             | When set to true, Wheels will show debugging information in the footers of your pages.                                                                                            |
| showErrorInformation  | boolean | Enabled in development, maintenance, and testing mode.                   | When set to false, Wheels will run and display code stored at app/events/onerror.cfm instead of revealing CFML errors.                                                            |

For more information, refer to the chapter about [Switching Environments](switching-environments.md).

### Caching Settings

Wheels does a pretty good job at caching the framework and its output to speed up your application. But if personalization is key in your application, finer control over caching settings will become more important.

Let's say your application generates dynamic routes and you need it to check the routes on each request. This task will be as simple as this line of code:

{% code title="CFScript" %}
```javascript
set(cacheRoutes=false);
```
{% endcode %}

**Full Listing of Caching Settings**

| Name                    | Type    | Default                                                      | Description                                                                                                                                                                                            |
| ----------------------- | ------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| cacheActions            | boolean | Enabled in maintenance, testing, and production              | When set to true, Wheels will cache output generated by actions when specified (in a caches() call, for example).                                                                                    |
| cacheControllerConfig   | boolean | Enabled in development, maintenance, testing, and production  | When set to false, any changes you make to the config() function in the controller file will be picked up immediately.                                                                                 |
| cacheCullInterval       | numeric | 5                                                            | Number of minutes between each culling action. The reason the cache is not culled during each request is to keep performance as high as possible.                                                      |
| cacheCullPercentage     | numeric | 10                                                           | If you set this value to 10, then at most, 10% of expired items will be deleted from the cache.                                                                                                        |
| cacheDatabaseSchema     | boolean | Enabled in development, maintenance, testing, and production | When set to false, you can add a field to the database, and Wheels will pick that up right away.                                                                                                     |
| cacheFileChecking       | boolean | Enabled in development, maintenance, testing, and production | When set to true, Wheels will cache whether or not controller, helper, and layout files exist                                                                                                        |
| cacheImages             | boolean | Enabled in development, maintenance, testing, and production | When set to true, Wheels will cache general image information used in imageTag() like width and height.                                                                                              |
| cacheModelConfig        | boolean | Enabled in development, maintenance, testing, and production | When set to false, any changes you make to the config() function in the model file will be picked up immediately.                                                                                      |
| cachePages              | boolean | Enabled in maintenance, testing, and production              | When set to true, Wheels will cache output generated by a view page when specified (in a renderView() call, for example).                                                                            |
| cachePartials           | boolean | Enabled in maintenance, testing, and production              | When set to true, Wheels will cache output generated by partials when specified (in a includePartial() call for example).                                                                            |
| cacheQueries            | boolean | Enabled in maintenance, testing, and production              | When set to true, Wheels will cache SQL queries when specified (in a findAll() call, for example).                                                                                                   |
| clearQueryCacheOnReload | boolean | true                                                         | Set to true to clear any queries that Wheels has cached on application reload.                                                                                                                       |
| cacheRoutes             | boolean | Enabled in development, maintenance, testing, and production | When set to true, Wheels will cache routes across all page views.                                                                                                                                     |
| defaultCacheTime        | numeric | 60                                                           | Number of minutes an item should be cached when it has not been specifically set through one of the functions that perform the caching in Wheels (i.e., caches(), findAll(), includePartial(), etc.) |
| maximumItemsToCache     | numeric | 5000                                                         | Maximum number of items to store in Wheels's cache at one time. When the cache is full, items will be deleted automatically at a regular interval based on the other cache settings.                 |

For more information, refer to the chapter on [Caching](../handling-requests-with-controllers/caching.md).

### ORM Settings

The Wheels ORM provides many sensible conventions and defaults, but sometimes your data structure requires different column naming or behavior than what Wheels expects out of the box. Use these settings to change those naming conventions or behaviors across your entire application.

For example, if we wanted to prefix all of the database table names in our application with `blog_` but didn't want to include that at the beginning of model names, we would do this:

{% code title="CFScript" %}
```javascript
set(tableNamePrefix="blog_");
```
{% endcode %}

Now your `post` model will map to the `blog_posts` table, `comment` model will map to the `blog_comments` table, etc.

**Full Listing of ORM Settings**

| Name                           | Type    | Default         | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------ | ------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| afterFindCallbackLegacySupport | boolean | true            | When this is set to false and you're implementing an afterFind() callback, you need to write the same logic for both the this scope (for objects) and arguments scope (for queries). Setting this to false makes both ways use the arguments scope so you don't need to duplicate logic. Note that the default is true for backwards compatibility.                                                                                                                                                                                                                                          |
| automaticValidations           | boolean | true            | Set to false to stop Wheels from automatically running object validations based on column settings in your database.                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| setUpdatedAtOnCreate           | boolean | true            | Set to false to stop Wheels from populating the updatedAt timestamp with the createdAt timestamp's value.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| softDeleteProperty             | string  | deletedAt       | Name of database column that Wheels will look for in order to enforce soft deletes.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| tableNamePrefix                | string  | \[empty string] | String to prefix all database tables with so you don't need to define your model objects including it. Useful in environments that have table naming conventions like starting all table names with tbl                                                                                                                                                                                                                                                                                                                                                                                      |
| timeStampOnCreateProperty      | string  | createdAt       | Name of database column that Wheels will look for in order to automatically store a "created at" time stamp when records are created.                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| timeStampOnUpdateProperty      | string  | updatedAt       | Name of the database column that Wheels will look for in order to automatically store an "updated at" time stamp when records are updated.                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| transactionMode                | string  | commit          | Use commit, rollback, or none to set default transaction handling for creates, updates and deletes.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| useExpandedColumnAliases       | boolean | false           | When set to true, Wheels will always prepend children objects' names to columns included via findAll()'s include argument, even if there are no naming conflicts. For example, model("post").findAll(include="comment") in a fictitious blog application would yield these column names: id, title, authorId, body, createdAt, commentID, commentName, commentBody, commentCreatedAt, commentDeletedAt. When this setting is set to false, the returned column list would look like this: id, title, authorId, body, createdAt, commentID, name, commentBody, commentCreatedAt, deletedAt. |
| modelRequireConfig             | boolean | false           | Set to true to have Wheels throw an error when it can't find a config() method for a model. If you prefer to always use config() methods, this setting could save you some confusion when it appears that your configuration code isn't running due to misspelling "config" for example.                                                                                                                                                                                                                                                                                                   |

### Plugin Settings

There are several settings that make plugin development more convenient. We recommend only changing these settings in `development` mode so there aren't any deployment issues in `production`, `testing`, and `maintenance`modes. (At that point, your plugin should be properly packaged in a zip file.)

If you want to keep what's stored in a plugin's zip file from overwriting changes that you made in its expanded folder, set this in `app/config/development/settings.cfm`:

{% code title="CFScript" %}
```javascript
set(overwritePlugins=false);
```
{% endcode %}

See the chapter on [Installing and Using Plugins](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/plugins/installing-and-using-plugins) for more information.

| Name                    | Type    | Default | Description                                                                                                                                                                                                                                                  |
| ----------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| deletePluginDirectories | boolean | true    | When set to true, Wheels will remove subdirectories within the plugins folder that do not contain corresponding plugin zip files. Set to false to add convenience to the process for developing your own plugins.                                          |
| loadIncompatiblePlugins | boolean | true    | Set to false to stop Wheels from loading plugins whose supported versions do not match your current version of Wheels.                                                                                                                                   |
| overwritePlugins        | boolean | true    | When set to true, Wheels will overwrite plugin files based on their source zip files on application reload. Setting this to false makes plugin development easier because you don't need to keep rezipping your plugin files every time you make a change. |
| showIncompatiblePlugins | boolean | false   | When set to true, an incompatibility warning will be displayed for plugins that do not specify the current Wheels version.                                                                                                                                 |

### Media Settings

Configure how Wheels handles linking to assets through view helpers like [imageTag()](https://wheels.dev/api/v3.0.0/controller.imagetag.html), [styleSheetLinkTag()](https://wheels.dev/api/v3.0.0/controller.stylesheetlinktag.html), and [javaScriptIncludeTag()](https://wheels.dev/api/v3.0.0/controller.javascriptincludetag.html).

See the chapter about [Date, Media, and Text Helpers](../displaying-views-to-users/date-media-and-text-helpers.md) for more information.

**Full Listing of Asset Settings**

| Name             | Type    | Default                                            | Description                                                                                                                                                                                                                                                                                                                                                   |
| ---------------- | ------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| assetQueryString | boolean | false in development mode, true in the other modes | Set to true to append a unique query string based on a time stamp to JavaScript, CSS, and image files included with the media view helpers. This helps force local browser caches to refresh when there is an update to your assets. This query string is updated when reloading your Wheels application. You can also hard code it by passing in a string. |
| assetPaths       | struct  | false                                              | Pass false or a struct with up to 2 different keys to autopopulate the domains of your assets: http (required) and https. For example: {http="asset0.domain1.com,asset2.domain1.com,asset3.domain1.com", https="secure.domain1.com"}                                                                                                                          |

### Routing Settings

Wheels includes a powerful routing system. Parts of it are configurable with the following settings.

See the chapters about [Using Routes](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/routing) and [Obfuscating URLs](../handling-requests-with-controllers/obfuscating-urls.md) for more information about how this all works together.

**Full Listing of Miscellaneous Settings**

| Name              | Type    | Default | Description                                                                               |
| ----------------- | ------- | ------- | ----------------------------------------------------------------------------------------- |
| loadDefaultRoutes | boolean | true    | Set to false to disable Wheels's default route patterns for controller/action/key, etc. |
| obfuscateUrls     | boolean | false   | Set to true to obfuscate primary keys in URLs.                                            |

### View Helper Settings

Wheels has a multitude of view helpers for building links, forms, form elements, and more. Use these settings to configure global defaults for their behavior.

| Name              | Type | Default                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Description                                                                                                                                                                                                                                                                     |
| ----------------- | ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| booleanAttributes | any  | allowfullscreen, async, autofocus, autoplay, checked, compact, controls, declare, default, defaultchecked, defaultmuted, defaultselected, defer, disabled, draggable, enabled, formnovalidate, hidden, indeterminate, inert, ismap, itemscope, loop, multiple, muted, nohref, noresize, noshade, novalidate, nowrap, open, pauseonexit, readonly, required, reversed, scoped, seamless, selected, sortable, spellcheck, translate, truespeed, typemustmatch, visible | A list of HTML attributes that should be allowed to be set as boolean values when added to HTML tags (e.g. `disabled` instead of `disabled="disabled"`). You can also pass in `true`(all attributes will be boolean) or `false` (no boolean attributes allowed, like in XHTML). |

### CSRF Protection Settings

Wheels includes built-in Cross-Site Request Forgery (CSRF) protection for form posts. Part of the CSRF protection involves storing an authenticity token in the session (default) or within an encrypted cookie. Most of the settings below are for when you've chosen to store the authenticity token within a cookie instead of the server's session store.

| Name                          | Type    | Default                | Description                                                                                                                                                                                                                                                                                                                                             |
| ----------------------------- | ------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| csrfStore                     | string  | session                | <p>Which storage strategy to use for storing the CSRF authenticity token. Valid values are <code>session</code> or <code>cookie</code>.<br><br>Choosing <code>session</code> requires no additional configuration.<br><br>Choosing <code>cookie</code> for this requires additional configuration listed below.</p>                                     |
| csrfCookieEncryptionAlgorithm | string  | AES                    | Encryption algorithm to use for encrypting the authenticity token cookie contents. This setting is ignored if you're using `session` storage. See your CF engine's documentation for the `Encrypt()`function for more information.                                                                                                                      |
| csrfCookieEncryptionSecretKey | string  |                        | Secret key used to encrypt the authenticity token cookie contents. This value must be configured to a string compatible with the `csrfCookieEncryptionAlgorithm`setting if you're using `cookie` storage. This value is ignored if you're using `session` storage. See your CF engine's documentation for the `Encrypt()`function for more information. |
| csrfCookieEncryptionEncoding  | string  | Base64                 | Encoding to use to write the encrypted value to the cookie. This value is ignored if you're using `session` storage. See your CF engine's documentation for the `Encrypt()` function for more information.                                                                                                                                              |
| csrfCookieName                | string  | \_wheels\_authenticity | The name of the cookie to be set to store CSRF token data. This value is ignored if you're using `session` storage.                                                                                                                                                                                                                                     |
| csrfCookieDomain              | string  |                        | Domain to set the cookie on. See your CF engine's documentation for `cfcookie` for more information.                                                                                                                                                                                                                                                    |
| csrfCookieEncodeValue         | boolean |                        | Whether or not to have CF encode the cookie. See your CF engine's documentation for `cfcookie` for more information.                                                                                                                                                                                                                                    |
| csrfCookieHttpOnly            | boolean | true                   | Whether or not they have CF set the cookie as `HTTPOnly`. See your CF engine's documentation for `cfcookie` for more information.                                                                                                                                                                                                                       |
| csrfCookiePath                | string  | /                      | Path to set the cookie on. See your CF engine's documentation for `cfcookie` for more information.                                                                                                                                                                                                                                                      |
| csrfCookiePreserveCase        | boolean |                        | Whether or not to preserve the case of the cookie's name. See your CF engine's documentation for `cfcookie` for more information.                                                                                                                                                                                                                       |
| csrfCookieSecure              | boolean |                        | Whether or not to only allow the cookie to be delivered over the HTTPS protocol. See your CF engine's documentation for `cfcookie` for more information.                                                                                                                                                                                                |

### CORS Protection Settings

Wheels includes built-in Cross-Origin Resource Sharing (CORS) which allows you to configure which cross-origin requests and methods are allowed. By default, this feature is turned off which will deny cross-origin requests at the browser level.&#x20;

In this first version, the user can enable this feature, which will allow requests from all origins and all methods.&#x20;

| Name              | Type    | Default |
| ----------------- | ------- | ------- |
| allowCorsRequests | boolean | false   |

### Miscellaneous Settings

| Name                    | Type    | Default | Description                                                                                                                              |
| ----------------------- | ------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| disableEngineCheck      | boolean | false   | Set to `true` if you don't want Wheels to block you from using older CFML engines (such as ColdFusion 9, Railo etc).                   |
| enableMigratorComponent | boolean | true    | Set to `false` to completely disable the migrator component which will prevent any Database migrations                                   |
| enablePluginsComponent  | boolean | true    | Set to `false` to completely disable the plugins component which will prevent any plugin loading, and not load the entire plugins system |
| enablePublicComponent   | boolean | true    | Set to `false` to completely disable the public component which will disable the GUI even in development mode                            |

### Migrator Configuration Settings

| Setting               | Type    | Default                          | Description                                                                                                                    |
| --------------------- | ------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| autoMigrateDatabase   | Boolean | false                            | Automatically runs available migration on applicationstart.                                                                    |
| migratorTableName     | String  | migratorversions                 | The name of the table that stores the versions migrated.                                                                       |
| createMigratorTable   | Boolean | true                             | Create the migratorversions database table.                                                                                    |
| writeMigratorSQLFiles | Boolean | false                            | Writes the executed SQL to a .sql file in the app/migrator/sql directory.                                                         |
| migratorObjectCase    | String  | lower                            | Specifies the case of created database object. Options are 'lower', 'upper' and 'none' (which uses the given value unmodified) |
| allowMigrationDown    | Boolean | false (true in development mode) | Prevents 'down' migrations (rollbacks)                                                                                         |
