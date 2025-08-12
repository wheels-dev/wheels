---
description: Instructions for upgrading Wheels applications
---

# Upgrading



Wheels follows Semantic Versioning ([http://semver.org/](http://semver.org)) so large version changes (e.g, `1.x.x -> 2.x.x`) will most likely contain breaking changes which will require evaluation of your codebase. Minor version changes (e.g, `1.3.x->1.4.x`) will often contain new functionality, but in a backwards-compatible manner, and maintenance releases (e.g `1.4.4 -> 1.4.5`) will just be trying to fix bugs.

Generally speaking, upgrading Wheels is as easy as replacing the `wheels` folder, especially for those small maintenance releases: however, there are usually exceptions in minor point releases (i.e, `1.1` to `1.3` required replacing other files outside the `wheels` folder). The notes below detail those changes.

### Upgrading to 3.0.0

#### Compatibility Changes

Adobe Coldfusion 2016 and below are no longer compatible with Wheels going forward. Consequently, these versions have been removed from the Wheels Internal Test Suites.

#### Code changes

* Migrate your tests from the `tests` directory which are written with rocketUnit and rewrite them into [Testbox](https://www.ortussolutions.com/products/testbox) in the `tests/Testbox` directory. Starting with Wheels 3.x, [Testbox](https://www.ortussolutions.com/products/testbox) will replace RocketUnit as the default testing framework.
* Starting with Wheels 3.x, [Wirebox](https://www.ortussolutions.com/products/wireboxhttps://www.ortussolutions.com/products/wirebox) will be used as the default dependency injector.
* After installing Wheels 3.x, you'll have to run `box install` to intall testbox and wirebox in your application as they are not shipped with Wheels but are rather listed in `box.json` file as dependencies to be installed.
* Added Mappings for the `app`, `vendor`, `wheels`, `wirebox`, `testbox` and `tests` directories.
* `root.cfm` and `rewrite.cfm` have been removed. All the requests are now being redirected only through `public/index.cfm`.
* A `.env` file has been added in the root of the application which adds the H2 database extension for lucee and sets the cfadmin password to `commandbox` for both [Lucee](http://lucee.org) and [Adobe ColdFusion](http://www.adobe.com/products/coldfusion/).

#### Changes to the wheels folder

* Replace the `wheels` folder with the new one from the 3.0.0 download.
* Move the `wheels` folder inside the `vendor` folder.

#### Changes outside the wheels folder

* Moved the `config`, `controllers`, `events`, `global`, `lib`, `migrator`, `models`, `plugins`, `snippets` and `views` directories inside the `app` directory.
* Moved the `files`, `images`, `javascripts`, `miscellaneous`, `stylesheets` directories and `Application.cfc`, `index.cfm` and `urlrewrite.xml` files into the `public` folder.

### Upgrading to 2.3.x

Replace the `wheels` folder with the new one from the 2.3.0 download.

### Upgrading to 2.2.x

Replace the `wheels` folder with the new one from the 2.2.0 download.

### Upgrading to 2.1.x

Replace the `wheels` folder with the new one from the 2.1.0 download.

#### Code changes

* Rename any instances of `findLast()` to `findLastOne()`

#### Changes outside the wheels folder

* Create `/events/onabort.cfm` to support the `onAbort` method

### Upgrading to 2.0.x

As always, the first step is to replace the `wheels` folder with the new one from the 2.0 download.

Other major changes required to upgrade your application are listed in the following sections.

#### Supported CFML Engines

Wheels 2.0 requires one of these CFML engines:

* Lucee 4.5.5.006 + / 5.2.1.9+
* Adobe ColdFusion 10.0.23 / 11.0.12+ / 2016.0.4+

We've updated our minimum requirements to match officially supported versions from the vendors. (For example, Adobe discontinued support for ColdFusion 10 in May 2017, which causes it to be exposed to security exploits in the future. We've included it in 2.0 but it may be discontinued in a future version)

#### Changes outside the wheels folder

* The `events/functions.cfm` file has been moved to `global/functions.cfm`.
* The `models/Model.cfc` file should extend `wheels.Model` instead of `Wheels` (`models/Wheels.cfc` can be deleted).
* The `controllers/Controller.cfc` file should extend `wheels.Controller` instead of `Wheels`(`controllers/Wheels.cfc` can be deleted).
* The `init` function of controllers and models must be renamed to `config`.
* The global setting `modelRequireInit` has been renamed to `modelRequireConfig`.
* The global setting `cacheControllerInitialization` has been renamed to `cacheControllerConfig`.
* The global setting `cacheModelInitialization` has been renamed to `cacheModelConfig`.
* The global setting `clearServerCache` has been renamed to `clearTemplateCache`.
* The `updateProperties()` method has been removed, use `update()` instead.
* JavaScript arguments like `confirm` and `disable` have been removed from the link and form helper functions (use the [JS Confirm](https://github.com/perdjurner/wheels-js-confirm) and [JS Disable](https://github.com/perdjurner/wheels-js-disable) plugins to reinstate the old behavior).
* The `renderPage` function has been renamed to `renderView`
* `includePartial()` now requires the `partial` and `query` arguments to be set (if using a query)

#### Routing

The [addRoute()](https://wheels.dev/api/v1.4.5) function has been removed in Wheels 2.0 in favor of a new routing API. See the [Routing](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing) chapter for information about the new RESTful routing system.

A limited version of the "wildcard" route (`[controller]/[action]/[key]`) is available as `[controller]/[action]`) if you use the new [wildcard()](https://wheels.dev/api/v3.0.0/mapper.wildcard.html) mapper method:

{% code title="/config/routes.cfm" %}
```javascript
mapper()
    .wildcard()
.end();
```
{% endcode %}

By default, this is limited to `GET` requests for security reasons.

#### Cross-Site Request Forgery (CSRF) Protection

It is strongly recommended that you enable Wheels 2.0's built-in CSRF protection.

For many applications, you need to follow these steps:

1. In `controllers/Controller.cfc`, add a call to [protectsFromForgery()](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/request-handling) to the `config` method.
2. Add a call to the [csrfMetaTags()](https://wheels.dev/api/v3.0.0/controller.csrfMetaTags.html) helper in your layouts' `<head>` sections.
3. Configure any AJAX calls that `POST` data to your application to pass the `authenticityToken` from the `<meta>`tags generated by [csrfMetaTags()](https://wheels.dev/api/v3.0.0/controller.csrfMetaTags.html) as an `X-CSRF-TOKEN` HTTP header.
4. Update your route definitions to enforce HTTP verbs on actions that manipulate data (`get`, `post`, `patch`, `delete`, etc.)
5. Make sure that forms within the application are `POST`ing data to the actions that require `post`, `patch`, and `delete` verbs.

See documentation for the [CSRF Protection Plugin](https://github.com/liquifusion/wheels-csrf-protection) for more information.

Note: If you had previously installed the [CSRF Protection plugin](https://github.com/liquifusion/wheels-csrf-protection), you may remove it and rely on the functionality included in the Wheels 2 core.

#### Database Migrations

If you have previously been using the dbmigrate plugin, you can now use the inbuilt version within the Wheels 2 core.&#x20;

Database Migration files in `/db/migrate/` should now be moved to `/app/migrator/migrations/` and extend `wheels.migrator.Migration`, not `plugins.dbmigrate.Migration` which can be changed with a simple find and replace. Note: Oracle is not currently supported for Migrator.

### Upgrading to 1.4.x

1. Replace the `wheels` folder with the new one from the 1.4 download.
2. Replace URL rewriting rule files – i.e, `.htaccess`, `web.config`, `IsapiRewrite.ini`

In addition, if you're upgrading from an earlier version of Wheels, we recommend reviewing the instructions from earlier reference guides below.

### Upgrading to 1.3.x

If you are upgrading from Wheels 1.1.0 or newer, follow these steps:

1. Replace the `wheels` folder with the new one from the 1.3 download.
2. Replace the root `root.cfm` file with the new one from the 1.3 download.
3. Remove the `<cfheader>` calls from the following files:
   * `events/onerror.cfm`
   * `events/onmaintenance.cfm`
   * `events/onmissingtemplate.cfm`

In addition, if you're upgrading from an earlier version of Wheels, we recommend reviewing the instructions from earlier reference guides below.

Note: To accompany the newest 1.1.x releases, we've highlighted the changes that are affected by each release in this cycle.&#x20;

### Upgrading to 1.1.x

If you are upgrading from Wheels 1.0 or newer, the easiest way to upgrade is to replace the wheels folder with the new one from the 1.1 download. If you are upgrading from an earlier version, we recommend reviewing the steps outlined in Upgrading to Wheels 1.0.

Note: To accompany the newest 1.1.x releases, we've highlighted the changes that are affected by each release in this cycle.

#### Plugin Compatibility

Be sure to review your plugins and their compatibility with your newly-updated version of Wheels. Some plugins may stop working, throw errors, or cause unexpected behavior in your application.

#### Supported System Changes

* 1.1: The minimum Adobe ColdFusion version required is now 8.0.1.
* 1.1: The minimum Railo version required is now 3.1.2.020.
* 1.1: The H2 database engine is now supported.

#### File System Changes

* 1.1: The .htaccess file has been changed. Be sure to copy over the new one from the new version 1.1 download and copy any addition changes that you may have also made to the original version.

#### Database Structure Changes

* 1.1: By default, Wheels 1.1 will wrap database queries in transactions. This requires that your database engine supports transactions. For MySQL in particular, you can convert your MyISAM tables to InnoDB to be compatible with this new functionality. Otherwise, to turn off automatic transactions, place a call to set(transactionMode="none").
* 1.1: Binary data types are now supported.

#### CFML Code Changes

**Model Code**

* 1.1: Validations will be applied to some model properties automatically. This may cause unintended behavior with your validations. To turn this setting off, call set(automaticValidations=false) in config/settings.cfm.
* 1.1: The class argument in hasOne(), hasMany(), and belongsTo() has been deprecated. Use the modelName argument instead.
* 1.1: afterFind() callbacks no longer require special logic to handle the setting of properties in objects and queries. (The "query way" works for both cases now.) Because arguments will always be passed in to the method, you can't rely on StructIsEmpty() to determine if you're dealing with an object or not. In the rare cases that you need to know, you can now call isInstance() or isClass() instead.
* 1.1: On create, a model will now set the updatedAt auto-timestamp to the same value as the createdAt timestamp. To override this behavior, call set(setUpdatedAtOnCreate=false) in config/settings.cfm.

**View Code**

* 1.1: Object form helpers (e.g. textField() and radioButton()) now automatically display a label based on the property name. If you left the label argument blank while using an earlier version of Wheels, some labels may start appearing automatically, leaving you with unintended results. To stop a label from appearing, use label=false instead.
* 1.1: The contentForLayout() helper to be used in your layout files has been deprecated. Use the includeContent() helper instead.
* 1.1: In production mode, query strings will automatically be added to the end of all asset URLs (which includes JavaScript includes, stylesheet links, and images). To turn off this setting, call set(assetQueryString=false) in config/settings.cfm.
* 1.1: stylesheetLinkTag() and javaScriptIncludeTag() now accept external URLs for the source/sources argument. If you manually typed out these tags in previous releases, you can now use these helpers instead.
* 1.1: flashMessages(), errorMessageOn(), and errorMessagesFor() now create camelCased class attributes instead (for example error-messages is now errorMessages). The same goes for the class attribute on the tag that wraps form elements with errors: it is now fieldWithErrors.

**Controller Code**

* 1.1.1: The if argument in all validation functions is now deprecated. Use the condition argument instead.

### Upgrading to 1.0.x

Our listing of steps to take while upgrading your Wheels application from earlier versions to 1.0.x.

Upgrading from an earlier version of 1.x? Then the upgrade path is simple. All you need to do is replace the wheels folder with the new wheels folder from the download.

The easiest way to upgrade is to setup an empty website, deploy a fresh copy of Wheels 1.0, and then transfer your application code to it. When transferring, please make note of the following changes and make the appropriate changes to your code.

Note: To accompany the newest 1.0 release, we've highlighted the changes that are affected by that release.

#### Supported System Changes

* 1.0: URL rewriting with IIS 7 is now supported.
* 1.0: URL rewriting in a sub folder on Apache is now supported.
* ColdFusion 9 is now supported.
* Oracle 10g or later is now supported.
* PostgreSQL is now supported.
* Railo 3.1 is now supported.

#### File System Changes

* 1.0: There is now an app.cfm file in the config folder. Use it to set variables that you'd normally set in Application.cfc (i.e., this.name, this.sessionManagement, this.customTagPaths, etc.)
* 1.0: There is now a web.config file in the root.
* 1.0: There is now a Wheels.cfc file in the models folder.
* 1.0: The Wheels.cfc file in the controllers folder has been updated.
* 1.0: The IsapiRewrite4.ini and .htaccess files in the root have both been updated.
* The controller folder has been changed to controllers.
* The model folder has been changed to models.
* The view folder has been changed to views.
* Rename all of your CFCs in models and controllers to UpperCamelCase. So controller.cfc will become Controller.cfc, adminUser.cfc will become AdminUser.cfc, and so on.
* All images must now be stored in the images folder, files in the files folder, JavaScript files in the javascripts folder, and CSS files in the stylesheets folder off of the root.

#### Database Structure Changes

* deletedOn, updatedOn, and createdOn are no longer available as auto-generated fields. Please change the names to deletedAt, updatedAt, and createdAt instead to get similar functionality, and make sure that they are of type datetime, timestamp, or equivalent.

#### CFML Code Changes

**Config Code**

* 1.0: The action of the default route (home) has changed to wheels. The way configuration settings are done has changed quite a bit. To change a Wheels application setting, use the new set() function with the name of the Wheels property to change. (For example, \<cfset set(dataSourceName="mydatasource")>.) To see a list of available Wheels settings, refer to the Configuration and Defaults chapter.\
  Model Code
* 1.0: The extends attribute in models/Model.cfc should now be Wheels.
* findById() is now called findByKey(). Additionally, its id argument is now named key instead. For composite keys, this argument will accept a comma-delimited list.
* When using a model's findByKey() or findOne() functions, the found property is no longer available. Instead, the functions return false if the record was not found.
* A model's errorsOn() function now always returns an array, even if there are no errors on the field. When there are errors for the field, the array elements will contain a struct with name, fieldName, and message elements.
* The way callbacks are created has changed. There is now a method for each callback event ( beforeValidation(), beforeValidationOnCreate(), etc.) that should be called from your model's init() method. These methods take a single argument: the method within your model that should be invoked during the callback event. See the chapter on Object Callbacks for an example.

**View Code**

* 1.0: The contents of the views/wheels folder have been changed.
* The wrapLabel argument in form helpers is now replaced with labelPlacement. Valid values for labelPlacement are before, after, and around.
* The first argument for includePartial() has changed from name to partial. If you're referring to it through a named argument, you'll need to replace all instances with partial.
* The variable that keeps a counter of the current record when using includePartial() with a query has been renamed from currentRow to current.
* There is now an included wheels view folder in views. Be sure to copy that into your existing Wheels application if you're upgrading.
* The location of the default layout has changed. It is now stored at /views/layout.cfm. Now controller-specific layouts are stored in their respective view folder as layout.cfm. For example, a custom layout for www.domain.com/about would be stored at /views/about/layout.cfm.
* In linkTo(), the id argument is now called key. It now accepts a comma-delimited list in the case of composite keys.
* The linkTo() function also accepts an object for the key argument, in which case it will automatically extract the keys from it for use in the hyperlink.
* The linkTo() function can be used only for controller-, action-, and route-driven links now. \* The url argument has been removed, so now all static links should be coded using a standard "a" tag.

**Controller Code**

* 1.0: The extends attribute in controllers/Controller.cfc should now be Wheels.\
  Multiple-word controllers and actions are now word-delimited by hyphens in the URL. For example, if your controller is called SiteAdmin and the action is called editLayout, the URL to access that action would be [http://www.domain.com/site-admin/edit-layout](http://www.domain.com/site-admin/edit-layout).

#### URL/Routing

* The default route for Wheels has changed from \[controller]/\[action]/\[id] to \[controller]/\[action]/\[key]. This is to support composite keys. The params.id value will now only be available as params.key.
* You can now pass along composite keys in the URL. Delimit multiple keys with a comma. (If you want to use this feature, then you can't have a comma in the key value itself).
