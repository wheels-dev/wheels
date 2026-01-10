---
description: How to speed up your website by caching content.
---

# Caching

If your website doesn't get a whole lot of traffic, then you can probably skip this chapter completely. Just remember that it's here, waiting for your triumphant return.

On the other hand, you're probably hoping for massive amounts of traffic to reach your website very soon, an imminent sell-out to Google, and a good life drinking Margaritas in the Caribbean. Knowing a little bit about the Wheels caching concepts will prepare you for this. (Except for the Margaritas... You're on your own with those ;).)

Consider a typical page on a Wheels website. It will likely call a controller action, get some data from your database using a finder method, and render the view for the user using some of the handy built-in functions.

All this takes time and resources on your web and database servers. Let's assume this page is accessed frequently, rarely changes, and looks the same for all users. Then you have a perfect candidate for caching.

### Configuring the Cache

Wheels will configure all caching parameters behind the scenes for you based on what environment mode you are currently in. If you leave everything to Wheels, caching will be optimized for the different environment modes (and set to have reasonable settings for cache size and culling). This means that all caching is off when working in Development mode but on when in Production mode, for example.

Here are the global caching parameters you can set, their default values, and a description of what they do. Because these are not meant to be set differently based on the environment mode, you would usually set these in the `/config/settings.cfm` file:

```
set(maximumItemsToCache=5000);
set(cacheCullPercentage=10);
set(cacheCullIntervalMinutes=5);
set(cacheDatePart="n");
set(defaultCacheTime=60);
set(cacheQueriesDuringRequest=true);
set(clearQueryCacheOnReload=true);
set(cachePlugins=true);
```

### maximumItemsToCache Setting

The total amount of items the cache can hold. When the cache is full, items will be deleted automatically at a regular interval based on the other settings below.

Note that the cache is stored in ColdFusion's `application` scope, so take this into consideration when deciding the number of items to store.

### cacheCullPercentage Setting

This is the percentage of items that are culled from the cache when `maximumItemsToCache` has been reached.

For example, if you set this value to 10, then at most, 10% of expired items will be deleted from the cache.

If you set this to 100, then all expired items will be deleted. Setting it to 100 is perfectly fine for small caches but can be problematic if the cache is very large.

### cacheCullInterval Setting

This is the number of minutes between each culling action. The reason the cache is not culled during each request is to keep performance as high as possible.

### cacheDatePart Setting

The measurement unit to use during caching. The default is minutes ("`n`"), but you can set it to seconds ("`s`") for example if you want more precise control over when a cached item should expire. For the rest of this chapter, we'll assume you've left it at the default setting.

### defaultCacheTime Setting

The number of minutes an item should be cached when it has not been specifically set through one of the functions that perform the caching in Wheels (i.e., `caches()`, `findAll()`, `includePartial()`, etc).

### cacheQueriesDuringRequest Setting

When set to `true`, Wheels caches identical queries during a request. See the section titled _Automatic Caching of Identical Queries_ below for more information about this setting.

### clearQueryCacheOnReload Setting

When set to `true`, Wheels will clear out all cached queries when doing a `reload=true` request. This is usually a good idea, but if you want to avoid hitting the database too hard on application reloads, you can set this to `false` to keep queries cached and ease the load on the database.

### cachePlugins Setting

If you set this to `false`, all plugins will reload on each request (as opposed to during `reload=true` requests only). Setting this is only recommended if you are developing a plugin yourself and need to see the impact of your changes as you develop it on a per-request basis.

### Environment-Level Caching

The following cache variables are usually set per environment mode:

```
// always turned on regardless of mode setting.
set(cacheControllerConfig = true);
set(cacheDatabaseSchema = true);
set(cacheModelConfig = true);
set(cachePlugins = true);

// Development mode example
set(cacheActions = false);
set(cacheFileChecking = false);
set(cacheImages = false);
set(cachePages = false);
set(cachePartials = false);
set(cacheQueries = false);
```

The settings shown above are what's in use in the Development mode. As you can see, when running in that mode, very little is cached. This makes it possible to do extensive changes without having to issue a `reload=true` request or restart the ColdFusion server, for example. The downside is that it makes for slightly slower development because the pages will not load as fast in this environment.

The variables themselves are fairly self-explanatory. When `cacheDatabaseSchema` is set to `false`, you can add a field to the database, and Wheels will pick that up right away. When `cacheModelConfig` is false, any changes you make to the `config()` function in the model file will be picked up. And so on.

{% hint style="info" %}
#### No more Design mode

Note that "Design" mode has been removed in Wheels 2.x: please use development mode instead.
{% endhint %}

Please refer to the [Configuration and Defaults](https://wheels.dev/3.0.0/guides/working-with-wheels/configuration-and-defaults) chapter for a complete listing of all the variables you can set and their default values.

### 4 Ways to Cache

In Wheels, you can cache data in 4 different ways:

* **Action** caching is the most effective of these methods because it caches the entire resulting HTML for the user.
* **Page** caching is similar to action caching, but it will only cache the view page itself and in reality, this caching method is rarely used.
* **Partial** caching is used when you only want to cache specific parts of pages. One reason for this could be that the page is personalized for a specific user, and you can only cache the sections that are not personalized.
* **Query** caching is the least effective of the 4 caching options because it only caches result sets that you get back from the database. But if you have a busy database and you're not too concerned with leaving pages/partials uncached, this could be a good option for you.

### Action Caching

This code specifies that you want to cache the `browseByUser` and `browseByTitle` actions for 30 minutes:

{% code title="Caches Example" %}
```javascript
component extends="Controller" {

   function config(){
     caches(actions="browseByUser,browseByTitle", time=30);
   }

   function browseByUser(){
     }

   function browseByTitle(){
     }
}
```
{% endcode %}

As you can see, the `caches()` function call goes inside the `config()` function at the top of your controller file and accepts a list of action names and the number of minutes the actions should be cached for.

So what happens when users request the `browseByUser` page?

When Wheels receives the first request for this page, it will handle everything as it normally would, with the exception that it also adds a copy of the resulting HTML to the cache before ending the processing.

Wheels creates an internal key for use in the cache as well. This key is created from the `controller, action, key`, and `params` variables. This means, for example, that paginated pages are all stored individually in the cache (because the URL variable for the page to display would be different on each request).

When the second user requests the same page, Wheels will serve the HTML directly from the cache.

All subsequent requests now get the cached page until it expires.

But there are 2 exceptions to this (which you can make good use of in your code to have the cache re-created at the right times). If the request is a post request (normally coming from a form submission) or if the Flash (you can read everything about the Flash in the [Using the Flash](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/using-the-flash) chapter) is not empty, then the cache won't be used. Instead, a new fresh page will be created.

One way to use this feature is to submit your forms to the same page to have it re-created or redirect to the cached page with a message in the Flash.

Here is some code that shows this technique with using the Flash to expire the cache. (Imagine that the `showArticle`page is cached and a user is adding a new comment to it.)

{% code title="Expire with Flash" %}
```javascript
flashInsert(message="Your comment was added");
redirectTo(action="showArticle", key=params.key);
```
{% endcode %}

Note that by default, any filters set for the action are being run as normal. This means that if you do authentication in the filter (which is a common technique for sites with content where you have to login first to see it), you can still cache those pages safely using the [caches()](https://wheels.dev/api/v3.0.0/controller.caches.html) function.

However, to achieve the fastest possible cache, you can override this default and tell Wheels to cache the HTML and serve that exactly as it is to all subsequent requests without running any filters. To do this, set the `static` argument on [caches()](https://wheels.dev/api/v3.0.0/controller.caches.html) to `true`. This will cache your content using the `cfcache` tag behind the scenes. This means that the Wheels framework won't even get involved with the subsequent requests until they expire from the cache again (please note that application events like `onSessionStart`, `onRequestStart`, etc. will run though).

### Page Caching

This code specifies that you want to cache the view page for the `browseByUser` action for 1 hour:

{% code title="browseByUser caches" %}
```javascript
component extends="Controller" {

   function browseByUser(){
     renderView(cache=60);
     }

   function browseByTitle(){
     }
}
```
{% endcode %}

The difference between action caching and page caching is that page caching will run the action and then only cache the view page itself. Action caching, as explained above, does not run the action code at all (but it does run filters and verifications).

### Partial Caching

When your site contains personalized information (maybe some text specifying who you are logged in as, a list of items in your shopping cart, etc.), then action caching is not an option, and you need to cache at a lower level. This is where being able to cache only specific parts of pages comes in handy.

In Wheels, this is done by using the `cache` argument in a call to [includePartial()](https://wheels.dev/api/v3.0.0/controller.includepartial.html) or [renderPartial()](https://wheels.dev/api/v3.0.0/controller.renderpartial.html). You can pass in `cache=true` or `cache=x` where `x` is the number of minutes you want to cache the partial for.

If you just pass in `true`, the default cache expiration time will be used.

So, for example, if you have an e-commerce site that lists products with a shopping cart in the sidebar, then you'd create a partial for the list of products and cache only that.

Example code:

{% code title="IncludePartial" %}
```javascript
#includePartial(partial="listing", cache=true)#
```
{% endcode %}

Behind the scenes Wheels creates the cache key based on the name of the partial plus all of the arguments passed in to it. This means that if you pass in a `userId` variable for example, they will be cached separately.

You can also use this to your advantage when it comes to expiring cached content. You could, for example, update an `updatedAt` property on a user object and pass that in to `includePartial`. As soon as it changes, Wheels will recreate the cached content (since the cache key is now different).

### Query Caching

You can cache result sets returned by your queries too. As a ColdFusion developer, this probably won't be new to you because you've always been able to use the `cachedwithin` attribute in the `<cfquery>` tag. The query caching in Wheels is very similar to this.

You can use query caching on all finder methods, and it looks like this:

```
users = model("user").findAll(where="name LIKE 'a%'", cache=10);
```

So there you have it: 4 easy ways to speed up your website!

### Automatic Caching of Identical Queries

When working with objects in Wheels, you'll likely find yourself using all of the convenient association functions Wheels makes available to you.

For example, if you have set up a `belongsTo` association from `article` to `author`, then you will likely write a lot of `article.author().name()` calls. In this case, Wheels is smart enough to only call the database once per request if the queries are identical. So don't worry about adding performance hits when making multiple calls like that in your code.

You can turn off this functionality either by using the `reload` argument to [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) (or any of the dynamic methods that end up calling [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) behind the scenes) or globally by adding `set(cacheQueriesDuringRequest=false)` to your configuration files.

The caching of these queries are stored on a per-model basis and Wheels will conveniently clear the cache for a model whenever anything changes in the database for a model (e.g. you call something that creates, updates or deletes records).
