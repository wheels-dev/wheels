---
description: >-
  Using Wheels to develop web applications with AJAX features is a breeze. You
  have several options and tools at your disposal, which we'll cover in this
  chapter.
---

# Tutorial: Wheels, AJAX, and You

Wheels was designed to be as lightweight as possible, so this keeps your options fairly open for developing AJAX features into your application.

While there are several flavors of JavaScript libraries out there with AJAX support, we will be using the [jQuery framework](http://jquery.com) in this tutorial. Let's assume that you are fairly familiar with the basics of jQuery and know how to set it up.

For this tutorial, let's create the simplest example of all: a link that will render a message back to the user without refreshing the page.

### A Simple Example

In this example, we'll wire up some simple JavaScript code that calls a Wheels action asynchronously. All of this will be done with basic jQuery code and built-in Wheels functionality.

First, let's make sure we've got an appropriate route setup. It might be you're still using the default `wildcard()` route which will create some default `GET` routes for the `controller/action` pattern, but we'll add a new route here just for practice. We are going to create a route named `sayHello` and direct it to the `hello` action of the `say` controller. There are two ways you could write this code a long hand method specifying the controller and action separately as well as a short hand method that combines the two into a single parameter.

The longhand way would look like:
{% code title="/config/routes.cfm" %}
```javascript
mapper()
  .get(name="sayHello", controller="say", action="hello")
.end()
```
{% endcode %}

The shorthand method would look like:
{% code title="/config/routes.cfm" %}
```javascript
mapper()
  .get(name="sayHello", to="say##hello")
.end()
```
{% endcode %}

You can decide which method you prefer. Both sets of code above are equivalent.

Then, let's create a link to a controller's action in a view file, like so:

{% code title="/app/views/say/hello.cfm" %}
```html
<cfoutput>

<!--- View code --->
<h1></h1>
<p></p>

#linkTo(text="Alert me!", route="sayHello", id="alert-button")#

</cfoutput>
```
{% endcode %}

That piece of code by itself will work just like you expect it to. When you click the link, you will load the `hello` action inside the `say` controller.

But let's make it into an asynchronous request. Add this JavaScript (either on the page inside `script` tags or in a separate `.js` file included via [javaScriptIncludeTag()](https://wheels.dev/api/v3.0.0/controller.javaScriptIncludeTag.html) ):

{% code title="JavaScript" %}
```javascript
(function($) {
    // Listen to the "click" event of the "alert-button" link and make an AJAX request
    $("#alert-button").on("click", function(event) {
        $.ajax({
            type: "GET",
            // References "/say/hello?format=json"
            url: $(this).attr("href") + "?format=json",
            dataType: "json",
            success: function(response) {
                $("h1").html(response.message);
                $("p").html(response.time);
            }
        });

        event.preventDefault();
    });
})(jQuery);
```
{% endcode %}

With that code, we are listening to the `click` event of the hyperlink, which will make an asynchronous request to the `hello` action in the `say` controller. Additionally, the JavaScript call is passing a URL parameter called `format` set to `json`.

Note that the `success` block inserts keys from the response into the empty `h1` and `p` blocks in the calling view. (You may have been wondering about those when you saw the first example. Mystery solved.)

The last thing that we need to do is implement the `say/hello` action. Note that the request expects a `dataType` of `JSON`. By default, Wheels controllers only generate HTML responses, but there is an easy way to generate JSON instead using Wheels's [provides()](https://wheels.dev/api/v3.0.0/controller.provides.html) and [renderWith()](https://wheels.dev/api/v3.0.0/controller.renderWith.html) functions:

{% code title="/app/controllers/Say.cfc" %}
```javascript
component extends="Controller" {
    function config() {
        provides("html,json");
    }

    function hello() {
        // Prepare the message for the user.
        greeting = {};
        greeting["message"] = "Hi there";
        greeting["time"] = Now();

        // Respond to all requests with `renderWith()`.
        renderWith(greeting);
    }
}
```
{% endcode %}

In this controller's `config()` method, we use the [provides()](https://wheels.dev/api/v3.0.0/controller.provides.html) function to indicate that we want all actions in the controller to be able to respond with the data in HTML or JSON formats. Note that the client calling the action can request the type by passing a URL parameter named format or by sending the `format` in the request header.

The call to [renderWith()](https://wheels.dev/api/v3.0.0/controller.renderWith.html) in the `hello` action takes care of the translation to the requested format. Our JavaScript is requesting JSON, so Wheels will format the `greeting` struct as JSON automatically and send it back to the client. If the client requested HTML or the default of none, Wheels will process and serve the view template at `/app/views/say/hello.cfm`. For more information about  [provides()](https://wheels.dev/api/v3.0.0/controller.provides.html) and  [renderWith()](https://wheels.dev/api/v3.0.0/controller.renderWith.html), reference the chapter on [Responding with Multiple Formats](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/responding-with-multiple-formats).

Lastly, notice the lines where we're setting `greeting["message"]` and `greeting["time"]`. Due to the case-insensitive nature of ColdFusion, we recommend setting variables to be consumed by JavaScript using bracket notation like that. If you do not use that notation (i.e., `greetings.message` and `greetings.time` instead), your JavaScript will need to reference those keys from the JSON as `MESSAGE` and `TIME` (all caps). Unless you like turning caps lock on and off, you can see how that would get annoying after some time.

Assuming you already included jQuery in your application and you followed the code examples above, you now have a simple AJAX-powered web application built on Wheels. After clicking that `Alert me!` link, your say controller will respond back to you the serialized message via AJAX. jQuery will parse the JSON object and populate the `h1` and `p`with the appropriate data.

### AJAX in Wheels Explained

That is it! Hopefully now you have a clearer picture on how to create AJAX-based features for your web applications.
