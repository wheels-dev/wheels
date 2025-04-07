---
description: Stop repeating yourself with the use of before and after filters.
---

# Using Filters

If you find the need to run a piece of code before or after several controller actions, then you can use _filters_ to accomplish this without needing to explicitly call the code inside each action in question.

This is similar to using the `onRequestStart` / `onRequestEnd` functions in CFML's `Application.cfc` file, with the difference being that filters tie in better with your CFWheels controller setup.

### An Example: Authenticating Users

One common thing you might find yourself doing is authenticating users before allowing them to see your content. Let's use this scenario to show how to use filters properly.

You might start out with something like this:

```javascript
component extends="Controller" {

  function secretStuff() {
        if ( !StructKeyExists(session, "userId") ) {
            abort;
        }
    }

    function evenMoreSecretStuff() {
        if ( !StructKeyExists(session, "userId") ) {
            abort;
        }
    }

}
```

Sure, that works. But you're already starting to repeat yourself in the code. What if the logic of your application grows bigger? It could end up looking like this:

```javascript
component extends="Controller" {

    function secretStuff() {
        if ( !find("212.55", cgi.remote_addr) ) {
            flashInsert(alert="Sorry, we're !open in that area.");
            redirectTo(action="sorry");
        } else if ( !StructKeyExists(session, "userId") ) {
            flashInsert(alert="Please login first.");
            redirectTo(action="login");
        }
    }

    function evenMoreSecretStuff() {
        if ( !find("212.55", cgi.remote_addr) ) {
            flashInsert(msg="Sorry, we're !open in that area.");
            redirectTo(action="sorry");
        } else if ( !StructKeyExists(session, "userId") ) {
            flashInsert(msg="Please login first.");
            redirectTo(action="login");
        }
    }

}
```

Ouch! You're now setting yourself up for a maintenance nightmare when you need to update that IP range, the messages given to the user, etc. One day, you are bound to miss updating it in one of the places.

As the smart coder that you are, you re-factor this to another function so your code ends up like this:

```javascript
component extends="Controller" {

    function secretStuff() {
        restrictAccess();
    }

    function evenMoreSecretStuff() {
        restrictAccess();
    }

    function restrictAccess() {
        if ( !find("212.55", cgi.remote_addr) ) {
            flashInsert(msg="Sorry, we're !open in that area.");
            redirectTo(action="sorry");
        } else if ( !StructKeyExists(session, "userId") ) {
            flashInsert(msg="Please login first!");
            redirectTo(action="login");
        }
    }

}
```

Much better! But CFWheels can take this process of avoiding repetition one step further. By placing a [filters()](https://api.cfwheels.org/controller.filters.html) call in the `config()` function of the controller, you can tell CFWheels what function to run before any desired action(s).

```javascript
component extends="Controller" {

    function config() {
        filters("restrictAccess");
    }

    private function restrictAccess() {
        if ( !find("212.55", cgi.remote_addr) ) {
            flashInsert(msg="Sorry, we're !open in that area.");
            redirectTo(action="sorry");
        } else if ( !StructKeyExists(session, "userId") ) {
            flashInsert(msg="Please login first!");
            redirectTo(action="login");
        }
    }

    function secretStuff() {
    }

    function evenMoreSecretStuff() {
    }

}
```

Besides the advantage of not having to call `restrictAccess()` twice, you have also gained two other things:

* The developer coding `secretStuff()` and `evenMoreSecretStuff()` can now focus on the main tasks of those two actions without having to worry about repetitive logic like authentication.
* The `config()` function is now starting to act like an overview for the entire controller.

All of these advantages will become much more obvious as your applications grow in size and complexity. This was just a simple example to put filters into context.

### Sharing Filters Between Controllers

So far, we've only been dealing with one controller. Unless you're building a very simple website, you'll end up with a lot more.

The question then becomes, "Where do I place the `restrictAccess()` function so I can call it from any one of my controllers?" The answer is that because all controllers extend `Controller.cfc`, you should probably put it there. The `config()` function itself with the call to [filters()](https://api.cfwheels.org/controller.filters.html) should remain inside your individual controllers though.

If you actually want to set the same filters to be run for all controllers, you can go ahead and move it to the `Controller.cfc` file's `config()` function as well. Keep in mind that if you want to run the `config()` function in the individual controller and in `Controller.cfc`, you will need to call `super.config()` from the `config()` function of your individual controller.

### Two Types of Filters

You specify if you want to run the filter function before or after the controller action with the `type` argument to the [filters()](https://api.cfwheels.org/controller.filters.html) function. It defaults to running it before the action.

The previous example with authentication showed a "before filter" in action. The other type of filter you can run is an "after filter." As you can tell from the name, an after filter executes code after the action has been completed.

This can be used to make some last minute modifications to the HTML before it is sent to the browser (think translation, compression, etc.), for example.

If you want to get a copy of the content that will be rendered to the browser from an after filter, you can use the [response()](https://api.cfwheels.org/controller.response.html) function. To set your changes to the response afterward, use the [setResponse()](https://api.cfwheels.org/controller.setresponse.html) function.

As an example, let's say that you want to translate the content to Gibberish before sending it to your visitor. You can do something like this:

```javascript
function config() {
    filters(through="translate", type="after");
}

private function translate() {
    setResponse(gibberify(response()));
}
```

### Including and Excluding Actions From Executing Filters

By default, filters apply to all actions in a controller. If that's not what you want, you can tell CFWheels to only run the filter on the actions you specify with the `only` argument. Or you can tell it to run the filter on all actions except the ones you specify with the `except` argument.

Here are some examples showing how to setup filtering in your controllers. Remember, these calls go inside the `config()` function of your controller file.

```javascript
filters(through="isLoggedIn,checkIPAddress", except="home,login");
filters(through="translateText", only="termsOfUse", type="after");
```

### Passing Arguments to Filter Functions

Sometimes it's useful to be able to pass through arguments to the filters. For one, it can help you reduce the amount of functions you need to write. Here's the easy way to pass through an argument:

```javascript
filters(through="authorize", byIP=true);
```

Now the `byIP` argument will be available in the `authorize` function.

To help you avoid any clashing of argument names, CFWheels also supports passing in the arguments in a struct as well:

```javascript
// The `through` argument would clash here if it wasn't stored within a struct
args.byIP = true;
args.through = true;
filters(through="authorize", authorizeArguments=args);
```

### Evaluating Filter Arguments at Runtime

Because your controller's `config()` function only runs once per application start, the passing of arguments can also be written as expressions to be evaluated at runtime. This is helpful if you need for the value to be dynamic from request to request.

For example, this code would only evaluate the value for `request.region` on the very first request, and CFWheels will store that particular value in memory for all subsequent requests:

```javascript
// This is probably not what you intended
filters(through="authorize", byIP=true, region=request.region);
```

To avoid this hard-coding of values from request to request, you can instead pass an expression. (The double pound signs are necessary to escape dynamic values within the string. We only want to store a string representation of the expression to be evaluated.)

```javascript
// This is probably more along the lines of what you intended
filters(through="authorize", byIP=true, region="##request.region##");
```

Now instead of evaluating `request.region` inside the `config()` function, it will be done on each individual request.

### Securing Your Filters

You probably don't want anyone to be able to run your filters directly (by modifying a URL on your website for example). To make sure that isn't possible we recommend that you always make them private. As you can see in all examples on this page we make sure that we always have `access="private"` in the function declaration for the filter.

### Low Level Access

If you need to access your filters on a lower level, you can do so by using the [filterChain()](https://api.cfwheels.org/controller.filterchain.html) and [setFilterChain()](https://api.cfwheels.org/controller.setfilterchain.html)functions. Typically, you'll want to call  [filterChain()](https://api.cfwheels.org/controller.filterchain.html) to return an array of all the filters set on the current controller, make your desired changes, and save it back using the [setFilterChain()](https://api.cfwheels.org/controller.setfilterchain.html) function.
