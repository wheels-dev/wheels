---
description: Simplify your views by breaking them down into partial page templates.
---

# Partials

Partials in Wheels act as a wrapper around the good old `<cfinclude>` tag. By calling [includePartial()](https://api.wheels.dev/controller.includepartial.html) or [renderPartial()](https://api.wheels.dev/controller.renderpartial.html), you can include other view files in a page, just like `<cfinclude>` would. But at the same time, partials make use of common Wheels features like layouts, caching, model objects, and so on.

These functions also add a few cool things to your development arsenal like the ability to pass in a query or array of objects and have the partial file called on each iteration (to name one).

### Why Use a Partial?

Websites often display the same thing on multiple pages. It could be an advertisement area that should be displayed in an entire section of a website or a shopping cart that is displayed while browsing products in a shop. You get the idea. To avoid duplicating code, you can place it in a file (the "partial" in Wheels terms) and include that file using [includePartial()](https://api.wheels.dev/controller.includepartial.html) on the pages that need it.

Even when there is no risk of code duplication, it can still make sense to use a partial. Breaking up a large page into smaller, more manageable chunks will help you focus on each part individually.

If you've used `<cfinclude>` a lot in the past (and who hasn't?!), you probably already knew all of this though, right?

### Storing Your Partial Files

To make it clear that a file is a partial and not a full page, we start the filename with an underscore character. You can place the partial file anywhere in the `app/views` folder. When locating partials, Wheels will use the same rules as it does for the `template` argument to [renderView()](https://api.wheels.dev/controller.renderview.html). This means that if you save the partial in the current controller's view folder, you reference it simply by its name.

For example, if you wanted to have a partial for a comment in your `blog` controller, you would save the file at `app/views/blog/_comment.cfm` and reference it (in [includePartial()](https://api.wheels.dev/controller.includepartial.html) and [renderPartial()](https://api.wheels.dev/controller.renderpartial.html)) with just "`comment`" as the first argument.

Sometimes it's useful to share partials between controllers though. Perhaps you have a banner ad that should be displayed across several controllers. One common approach then is to save them in a dedicated folder for this at the root of the `app/views` folder. To reference partials in this folder, in this case named shared, you would then pass in `"/shared/banner"` to [includePartial()](https://api.wheels.dev/controller.includepartial.html) instead.

### Making the Call

Now that we know why we should use partials and where to store them, let's make a call to [includePartial()](https://api.wheels.dev/controller.includepartial.html) from a view page to have Wheels display a partial's output.

```javascript
#includePartial("banner")#
```

That code will look for a file named `_banner.cfm` in the current controller's view folder and include it.

Let's say we're in the `blog` controller. Then the file that will be included is `app/views/blog/_banner.cfm`.

As you can see, you don't need to specify the `.cfm` part or the underscore when referencing a partial.

### Passing in Data

You can pass in data by adding named arguments on the [includePartial()](https://api.wheels.dev/controller.includepartial.html) call. Because we use the `partial` argument to determine what file to include, you can't pass in a variable named partial though. The same goes for the other arguments as well, like `layout`, `spacer`, and `cache`.

Here is an example of passing in a title to a partial for a form:

```javascript
#includePartial(partial="loginRegisterForm", title="Please log in here")#
```

Now you can reference the title variable as `arguments.title` inside the `_loginregisterform.cfm` file.

If you prefer, you can still access the view variables that are set outside of the partial. The advantage with specifically passing them in instead is that they are then scoped in the `arguments` struct (which means less chance of strange bugs occurring due to variable conflicts). It also makes for more readable and maintainable code. (You can see the intent of the partial better when you see what is passed in to it).

{% hint style="info" %}
#### Special arguments

The `query`, `object` and `objects` arguments are special arguments and should not be used for other purposes than what's documented in the sections further down on this page.
{% endhint %}

### Automatic Calls to a Data Function

There is an even more elegant way of passing data to a partial though. When you start using a partial on several pages on a site spread across multiple controllers, it can get quite cumbersome to remember to first load the data in an appropriate function in the controller, setup a before filter for it, pass that data in to the partial, and so on.

Wheels can automate this process for you. The convention is that a partial will always check if a function exists on the controller with the same name as the partial itself (and that it's set to `private` and will return a struct). If so, the partial will call the function and add the output returned to its `arguments` struct.

This way, the partial can be called from anywhere and acts more like a "black box." All communication with the model is kept in the controller as it should be for example.

If you don't want to load the data from a function with the same name as the partial (perhaps due to it clashing with another function name), you can specify the function to load data from with the `dataFunction` argument to [includePartial()](https://api.wheels.dev/controller.includepartial.html) and [renderPartial()](https://api.wheels.dev/controller.renderpartial.html).

### Partials with Layouts

Just like a regular page, Wheels partials also understand the concept of layouts. To use this feature, simply pass in the name of the layout file you want to wrap the partial in with the `layout` argument, like this:

```javascript
#includePartial(partial="newsItem", layout="/boxes/blue")#
```

This will wrap the partial with the code found in `app/views/boxes/_blue.cfm`. Just like with other layouts, you use [includeContent()](https://api.wheels.dev/controller.includecontent.html) to represent the partial's content.

That said, your `_blue.cfm` file could end up looking something like this:

```javascript
<div class="news">
    #includeContent()#
</div>
```

One difference from page layouts is that the layout file for partials has to start with the underscore character.

It's also worth noting that it's perfectly acceptable to include partials inside layout files as well. This opens up the possibility to nest layouts in complex ways.

### Caching a Partial

Caching a partial is done the same way as caching a page. Pass in the number of minutes you want to cache the partial for to the `cache` argument.

Here's an example where we cache a partial for 15 minutes:

```javascript
#includePartial(partial="userListing", cache=15)#
```

### Using Partials with an Object

Because it's quite common to use partials in conjunction with objects and queries, Wheels has built-in support for this too. Have a look at the code below, which passes in an object to a partial:

```javascript
cust = model("customer").findByKey(params.key);
#includePartial(cust)#
```

That code will figure out that the `cust` variable contains a `customer` model object. It will then try to include a partial named `_customer.cfm` and pass in the object's properties as arguments to the partial. There will also be an `object`variable available in the `arguments` struct if you prefer to reference the object directly.

Try that code and `<cfdump>` the `arguments` struct inside the partial file, and you'll see what's going on. Pretty cool stuff, huh?

### Using Partials with a Query

Similar to passing in an object, you can also pass in a query result set to [includePartial()](https://api.wheels.dev/controller.includepartial.html). Here's how that looks:

```javascript
customers = model("customer").findAll();
#includePartial(partial="customers", query=customers)#
```

In this case, Wheels will iterate through the query and call the `_customer.cfm` partial on each iteration. Similar to the example with the object above, Wheels will pass in the objects' properties (in this case represented by records in the query) to the partial.

In addition to that, you will also see that a counter variable is available. It's named `current` and is available when passing in queries or arrays of objects to a partial.

The way partials handle objects and queries makes it possible to use the exact same code inside the partial regardless of whether we're dealing with an object or query record at the time.

If you need to display some HTML in between each iteration (maybe each iteration should be a list item for example), then you can make use of the `spacer` argument. Anything passed in to that will be inserted between iterations. Here's an example:

```javascript
<ul>
    <li>#includePartial(partial=customers, query=customers, spacer="</li><li>")#</li>
</ul>
```

### Partials and Grouping

There is a feature of CFML that is very handy: the ability to output a query with the group attribute. Here's an example of how this can be done with a query that contains artists and albums (with the artist potentially being duplicated since they can have more than one album):

```javascript
<cfoutput query="artistsAndAlbums" group="artistid">
    <!--- Artist info is displayed just once for each artist here --->
    <cfoutput>
        <!--- Each album is looped here --->
    </cfoutput>
</cfoutput>
```

We have ported this great functionality into calling partials with queries as well. Here's how you can achieve it:

```javascript
#includePartial(partial=artistsAndAlbums, query=artistsAndAlbums, group="artistId")#
```

When inside the partial file, you'll have an additional subquery made available to you named `group`, which contains the albums for the current artist in the loop.

### Using Partials with an Array of Objects

As we've hinted previously in this chapter, it's also possible to pass in an array of objects to a partial. It works very similar to passing in a query in that the partial is called on each iteration.

### Rendering or Including?

So far we've only talked about [includePartial()](https://api.wheels.dev/controller.includepartial.html), which is what you use from within your views to include other files. There is another similar function as well: [renderPartial()](https://api.wheels.dev/controller.renderpartial.html). This one is used from your controller files when you want to render a partial instead of a full page. At first glance, this might not make much sense to do. There is one common usage of this though—AJAX requests.

Let's say that you want to submit comments on your blog using AJAX. For example, the user will see all comments, enter their comment, submit it, and the comment will show up below the existing ones without a new page being loaded.

In this case, it's useful to use a partial to display each comment (using [includePartial()](https://api.wheels.dev/controller.includepartial.html) as outlined above) and use the same partial when rendering the result of the AJAX request.

Here's what your controller action that receives the AJAX form submission would look like:

```javascript
comment = model("comment").create(params.newComment);
renderPartial(comment);
```

Please note that there currently is no support for creating the AJAX form directly with Wheels. This can easily be implemented using a JavaScript library such as jQuery or Prototype though.
