---
description: Where to place your view files and what to put in them.
---

# Pages

We've talked previously about how the controller is responsible for deciding which view files to render to the user. Read the [Rendering Content](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/rendering-content) chapter if you need to refresh your memory about that topic.

In this chapter, we'll explain exactly _where_ to place these files and _what_ to put in them.

### Where to Place the Files

In the simplest case, your controller action (typically a function inside your controller CFC file) will have a view file associated with it. As explained in the [Rendering Content](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/rendering-content) chapter, this file will be included automatically at the end of the controller action code. So if you're running the `show` action in the `blog` controller, for example, Wheels will include the `app/views/blog/show.cfm` file.

Some rules can be spotted here:

* All view files live in the `app/views` folder.
* Each controller gets a subfolder named after it in the `app/views` folder.
* The view file to include is just a regular `.cfm` file named after the action.

For creating standard pages, your work process will likely consist of the following steps:

1. Create the controller action (a function in the controller CFC file).
2. Create the corresponding view file for it (a `.cfm` file in the controller's view folder).

There can be some exceptions to this process though, so let's go through some possible scenarios.

### Controller Actions Without Associated View Files

Not all controller actions need a corresponding view file. Consider the case where you process a form submission. To make sure it's not possible for the user to refresh the page and cause multiple submissions, you may choose to perform the form processing and then send the user directly to another page using the [redirectTo()](https://api.wheels.dev/controller.redirectto.html) function.

### Rendering the View File for Another Action

Sometimes you want the controller action to render the view file for a different action than the one currently executing. This is especially common when your application processes a form and the user makes an input error. In this case, you'll probably choose to have your application display the same form again for correction.

In this case, you can use the [renderView()](https://api.wheels.dev/controller.renderview.html) function and specify a different action in the `action` argument (which will include the view page for that action but not **run** the controller code for it).

### Sharing a View File Between Actions

Sometimes it's useful to have a view file that can be called from several controller actions. For these cases, you'll typically call [renderView()](https://api.wheels.dev/controller.renderview.html) with the `template` argument.

When using the `template` argument, there are specific rules that Wheels will follow in order to locate the file you want to include:

* If the template argument starts with the `/` character, Wheels will start searching from the `app/views` folder. Example: `renderView(template="/common/page")` will include the `app/views/common/page.cfm` file.
* If it contains the `/` character elsewhere in the string, the search will start from the controller's view folder. Example: `renderView(template="misc/page")` will include the `app/views/blog/misc/page.cfm` file if we're currently in the `blog` controller.
* In all other cases (i.e. when the template argument does not contain the `/` character at all), Wheels will just assume the file is in the controller's view folder and try to include it. Example: `renderView(template="something")` will include the `app/views/blog/something.cfm` file if we're currently in the `blog` controller.

Also note that both `renderView(template="thepage")` and `renderView(template="thepage.cfm")` work fine. But most of the time, Wheels developers will tend to leave out the `.cfm` part.

### What Goes in the Files?

This is the output of your application: what the users will see in their browsers. Most often this will consist of HTML, but it can also be JavaScript, CSS, XML, etc. You are of course free to use any CFML tags and functions that you want to in the file as well. (This is a CFML application, right?)

In addition to this normal code that you'll see in most ColdFusion applications—whether they are made for a framework or not—Wheels also gives you some nice constructs to help keep your code clean. The most important ones of these are [Layouts](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/displaying-views-to-users/layouts) , Partials, and Helpers.

When writing your view code, you will have access to the variables you have set up in the controller file. The idea is that the variables you want to access in the view should be set unscoped (or in the `variables` scope if you prefer to set it explicitly) in the controller so that they are available to the view template.

In addition to the variables you have set yourself, you can also access the `params` struct. This contains anything passed in through the URL or with a form. If you want to follow MVC rules more closely though, we recommend only accessing the `params` struct in the controller and then setting new variables for the information you need access to in the view.

The most important thing to remember when creating your view is to be careful not to put too much code in there. Avoid code dealing with the incoming request (this can be moved to the controller) and code containing business logic (consider moving this to a model). If you have view-related code but too much of it, it may be beneficial to break it out into a helper or a partial.

### Cleaning Up Output

A view's job is also to clean up and format the values provided by the controller before being displayed. This is especially important when content from a data source is not HTML-encoded.

For example, if the view is to display the `title` column from a query object called `posts`, it should encode HTML special characters:

```javascript
<ul>
    <cfoutput query="posts">
        <li>#EncodeForHtml(posts.title)#</li>
    </cfoutput>
</ul>
```

Please note that you do **not** need to do this when passing in data to Wheels view helpers. The view helpers themselves will handle calling `EncodeForUrl`, `EncodeForHtml` and `EncodeForHtmlAttribute` internally as needed.

By "view helpers" we mean everything listed as such in the [API reference](https://api.wheels.dev/), so be aware that global helpers, such as [capitalize](https://api.wheels.dev/controller.capitalize.html), [humanize](https://api.wheels.dev/controller.humanize.html) etc, do not encode the content you pass in. When in doubt, simply test by passing in a string and check the HTML source of the output to see whether Wheels encoded it or not.

To control encoding in general you have three global settings at your disposal (they all default to `true`):

* `encodeURLs`: When `true`, calls `EncodeForUrl` to encode parameter name and values in [URLFor](https://api.wheels.dev/controller.urlfor.html).
* `encodeHtmlTags`: When `true`, calls `EncodeForHtml` to encode tag content in [linkTo](https://api.wheels.dev/controller.linkto.html), [textAreaTag](https://api.wheels.dev/controller.textareatag.html) etc.
* `encodeHtmlAttributes`: When `true`, calls `EncodeForHtmlAttribute` to encode attribute values in [linkTo](https://api.wheels.dev/controller.linkto.html), [textAreaTag](https://api.wheels.dev/controller.textareatag.html) etc.

All individual functions also have their own `encode` argument (can be set to `true` / `false` or `attributes`) that overrides the global setting. Setting it to `attributes` will only encode HTML attribute values but leave tag content as is. Note that the `attributes` option is not available on functions that don't produce any tag content (such as [imageTag](https://api.wheels.dev/controller.imagetag.html) for example), in those cases it's enough to pass in either `true` or `false`.
