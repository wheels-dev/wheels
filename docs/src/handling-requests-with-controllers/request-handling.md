---
description: How Wheels handles an incoming request
---

# Request Handling

Wheels is quite simple when it comes to figuring out how incoming requests map\
to code in your application. Let's look at a URL for an e-commerce website and\
dissect it a little.

But before we do that, a quick introduction to URLs in Wheels is in order.

### A Wheels URL

URLs in Wheels generally look something like this:

```
http://localhost:8080/index.cfm/shop/products
```

It's also possible that the URLs will look like this in your application:

```
http://localhost:8080/index.cfm?controller=shop&action=products
```

This happens when your web server does not support the `cgi.path_info` variable.

Regardless of your specific setup, Wheels will try to figure out how to handle\
the URLs. If Wheels fails to do this properly (i.e. you _know_ that your web\
server supports `cgi.path_info`, but Wheels insists on creating the URLs with\
the query string format), you can override it by setting `URLRewriting` in\
`/config/settings.cfm` to either `On, Partial`, or `Off`. The line of code should\
look something like this:

```javascript
set(URLRewriting="Partial");
```

"Partial URL Rewriting" is what we call that first URL up there with the\
`/index.cfm/` format.

In the example URLs used above, `shop` is the name of the controller to call,\
and `products` is the name of the action to call on that controller.

### Model-View-Controller Explained

Unless you're familiar with the Model-View-Controller pattern, you're probably\
wondering what controllers and actions are.

Put very simply, a _controller_ takes an incoming request and, based on the\
parameters in the URL, decides what (if any) data to get from the model (which\
in most cases means your database), and decides which view (which in most cases\
means a CFML file producing HTML output) to display to the user.

An _action_ is an entire process of executing code in the controller, including\
a view file and rendering the result to the browser. As you will see in the\
example below, an action usually maps directly to one specific function with the\
same name in the controller file.

### Creating URLs

Mapping an incoming URL to code is only one side of the equation. You will also\
need a way to create these URLs. This is done through a variety of different\
functions like [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) (for creating links), [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startformtag.html) (for\
creating forms), and [redirectTo()](https://wheels.dev/api/v3.0.0/controller.redirectto.html) (for redirecting users), to name a few.

Internally, all of these functions use the same code to create the URL, namely\
the [URLFor()](https://wheels.dev/api/v3.0.0/controller.urlfor.html) function. The [URLFor()](https://wheels.dev/api/v3.0.0/controller.urlfor.html) function accepts a controller and\
an action argument, which are what you will use most of the time. It has a lot\
of other arguments and does some neat stuff (like defaulting to the current\
controller when you don't specifically pass one in). So check out the\
documentation for the [URLFor()](https://wheels.dev/api/v3.0.0/controller.urlfor.html) function for all the details.

By the way, by using URL rewriting in Apache or IIS, you can completely get rid\
of the `index.cfm` part of the URL so that\
`http://localhost:8080/index.cfm/shop/products` becomes\
`http://localhost:8080/shop/products`. You can read more about this in the\
[URL Rewriting](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/url-rewriting/README) chapter.

For the remainder of this chapter, we'll type out the URLs in this shorter and\
prettier way.

### A Wheels Page

Let's look a little closer at what happens when Wheels receives this example\
incoming request.

First, it will create an instance of the `shop` controller\
(`/app/controllers/Shop.cfc`) and call the function inside it named `products`.

Let's show how the code for the `products` function could look to make it more\
clear what goes on:

{% code title="Shop.cfc" %}
```javascript
component extends="Controller" {

    function products() {
        renderView(controller="shop", action="products");
    }

}
```
{% endcode %}

The only thing this does is specify the view page to render using the\
[renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) function.

The [renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) function is available to you because the `shop` controller extends the main Wheels `Controller`component. Don't forget to include that `extends` attribute in your `cfcomponent` call as you build your controllers!

So, how does [renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) work? Well, it accepts the arguments `controller` and `action` (among others, such as `route`), and, based on these, it will try to include a view file. In our case, the view file is stored at `/app/views/shop/products.cfm`.

You can read the chapter about [Rendering Content](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/rendering-content) for more information about the [renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) function.

It's important to note that the [renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) function does not cause any controller actions or functions to be executed. It just specifies what view\
files to get content from. Keep this in mind going forward because it's a common assumption that it does. (Especially when you want to include the view page for another action, it's easy to jump to the incorrect conclusion that the code for that action would also get executed.)

### Wheels Conventions

Because Wheels favors convention over configuration, we can remove a lot of the\
code in the example above, and it will still work because Wheels will just guess\
what your intention is. Let's have a quick look at exactly what code can be\
removed and why.

The first thing Wheels assumes is that if you call [renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) without\
arguments, you want to include the view page for the **current** controller and\
action.

Therefore, the code above can be changed to:

{% code title="Shop.cfc" %}
```javascript
component extends="Controller" {

    function products() {
        renderView();
    }

}
```
{% endcode %}

… and it will still work just fine.

Does Wheels assume anything else? Sure it does. You can actually remove the\
entire [renderView()](https://wheels.dev/api/v3.0.0/controller.renderview.html) call because Wheels will assume that you always want to call a view page when the processing in the controller is done. Wheels will call\
it for you behind the scenes.

That leaves you with this code:

{% code title="Shop.cfc" %}
```javascript
component extends="Controller" {

    function products() { 
    }

}
```
{% endcode %}

That looks rather silly, a `products` function with no code whatsoever. What do\
you think will happen if you just remove that entire function, leaving you with\
this code?

{% code title="Shop.cfc" %}
```javascript
component extends="Controller" { 

}
```
{% endcode %}

…If you guessed that Wheels will just assume you don't need any code for the\
`products` action and just want the view rendered directly, then you are correct.

In fact, if you have a completely blank controller like the one above, you can\
delete it from the file system altogether!

This is quite useful when you're just adding simple pages to a website and you\
don't need the controller and model to be involved at all. For example, you can\
create a file named `about.cfm` in the `/app/views/home` folder and access it at\
`http://localhost:8080/home/about` without having to create a specific controller\
and/or action for it, assuming you're still using wildcard routing.

This also highlights the fact that Wheels is a very easy framework to get\
started in because you can basically program just as you normally would by\
creating simple pages like this and then gradually "Wheelsifying" your code as\
you learn the framework.

### The `params` Struct

Besides making sure the correct code is executed, Wheels also does something\
else to simplify request handling for you. It combines the `url` and `form`\
scopes into one. This is something that most CFML frameworks do as well. In\
Wheels, it is done in the `params` struct.

The `params` struct is available to you in the controller and view files but\
not in the model files. (It's considered a best practice to not mix your request\
handling with your business logic.) Besides the `form` and `url` scope\
variables, the `params` struct also contains the current controller and action\
name for easy reference.

If the same variable exists in both the `url` and `form` scopes, the value in\
the form scope will take precedence.

To make this concept easier to grasp, imagine a login form on your website that\
submits to `http://localhost:8080/account/login?sendTo=dashboard` with the variables\
`username` and `password` present in the form. Your `params` struct would look\
like this:

| Name              | Value     |
| ----------------- | --------- |
| params.controller | account   |
| params.action     | login     |
| params.sendTo     | dashboard |
| params.username   | joe       |
| params.password   | 1234      |

Now instead of accessing the variables as `url.sendTo`, `form.username`, etc.,\
you can just use the `params` struct for all of them instead.

This concept becomes even more useful once we start getting into creating forms\
specifically meant for accessing object properties. But let's save the details\
of all that for the [Form Helpers and Showing Errors](https://wheels.dev/3.0.0/guides/displaying-views-to-users/form-helpers-and-showing-errors) chapter.

### JSON as part of the request body

If you're constructing a JSON API, you're inevitably going to come across how to deal with "incoming" json packets to your routing endpoints. Instead of having to test each request with whether it's valid json etc, Wheels will automatically map the JSON body in a request to the params struct, as long as it has `application/json` as it's mime type.

So in the same way that the `url` and `form` scopes are merged, so a valid `json` body would be. The exception to the rule is when a javascript array is the root element, where it's then added to `params._json` to follow Rails conventions. (For obvious reasons, we can't merge an array into a struct!)

{% hint style="info" %}
#### NOTE

The mapping of a json array to params.\_json was introduced in Wheels 2.1
{% endhint %}

### Routing

For more advanced URL-to-code mappings, you are encourage to use a concept called _routing_.\
It allows for you to fully customize every URL in your application, including which HTTP verb can be used. You can read more about this in the chapter called [Routing](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing).
