---
description: Using the Flash to pass data from one request to the next.
---

# Using the Flash

The Flash is actually a very simple concept. And no, it has nothing to do with\
Adobe's Flash Player.

The Flash is just a struct in the `session` or `cookie` scope with some added\
functionality. It is cleared at the end of the next page that the user views.\
This means that it's a good fit for storing messages or variables temporarily\
from one request to the next.

By the way, the name "Flash" comes from Ruby on Rails, like so many other cool\
things in Wheels.

### An Example of Using the Flash

The code below is commonly used in Wheels applications to store a message about\
an error in the Flash and then redirect to another URL, which then displays the message in its view page.

The following example shows how code dealing with the Flash can look in an\
action that handles a form submission.

```javascript
function update() {
    if ( user.update(params.user) ) {
        flashInsert(success="The user was updated successfully.");
        redirectTo(action="edit");
    } else {
        renderView(action="edit");
    }
}
```

Here's an example of how we then display the Flash message we just set in the\
view page for the `edit` action. Please note that this is done on the _next_\
request since we performed a redirect after setting the Flash.

```html
<cfoutput>
<p class="success-message">
    #flash("success")#
</p>
</cfoutput>
```

As you can see above, you use the [flashInsert()](https://wheels.dev/api/v3.0.0/controller.flashinsert.html) function with a named argument when you want to store data in the Flash and the [flash()](https://wheels.dev/api/v3.0.0/controller.flash.html) function when you want to display the data in a view.

The key chosen above is `success`, but it could have been anything that we wanted. Just like with a normal struct, the naming of the keys is your job.

As an example, you may choose to use one key for storing messages after the user made an error, called `error`, and another one for storing messages after a successful user operation, called `success`.

### Shortcut for Setting the Flash and Redirecting

The more you work with Wheels and the Flash, the more that you're going to find\
that you keep repeating that [flashInsert()](https://wheels.dev/api/v3.0.0/controller.flashinsert.html)/ [redirectTo()](https://wheels.dev/api/v3.0.0/controller.redirectto.html) combo all\
the time. Wheels has a solution for that within the [redirectTo()](https://wheels.dev/api/v3.0.0/controller.redirectto.html) function\
itself:&#x20;

```javascript
redirectTo(action="edit", success="The user was updated successfully.");
```

That piece of code does exactly the same thing as the example shown previously\
in this chapter. The Wheels [redirectTo()](https://wheels.dev/api/v3.0.0/controller.redirectto.html) function sees the `success`\
argument coming in and knows that it's not part of its own declared arguments.

Therefore, you (the developer) must intend for it to be stored in the Flash,\
so Wheels goes ahead and calls `flashInsert(success="The user was updated successfully.")`\
for you behind the scenes.

### Prepend with flash for Argument Names that Collide with redirectTos

So what if you want to redirect to the `edit` action and set a key in the Flash\
named `action` as well? Simply prepend the key with `flash` to tell Wheels to\
avoid the argument naming collision.

CFScript

```javascript
redirectTo(action="edit", flashAction="The user was updated successfully.");
```

We don't recommend naming the keys in your Flash `action`, but these naming\
collisions can potentially happen when you want to redirect to a route that\
takes custom arguments, so remember this workaround.

### More Flashy Functions

Besides [flash()](https://wheels.dev/api/v3.0.0/controller.flash.html) and [flashInsert()](https://wheels.dev/api/v3.0.0/controller.flashinsert.html) that are used to read\
from/insert to the Flash, there are a few other functions worth mentioning.

[flashCount()](https://wheels.dev/api/v3.0.0/controller.flashcount.html) is used to count how many key/value pairs there are in the\
Flash.

[flashClear()](https://wheels.dev/api/v3.0.0/controller.flashclear.html) and [flashDelete()](https://wheels.dev/api/v3.0.0/controller.flashdelete.html) do exactly the same as their\
counterparts in the struct world, `StructClear` and `StructDelete`—they clear\
the entire Flash and delete a specific key/value from it, respectively.

[flashKeyExists()](https://wheels.dev/api/v3.0.0/controller.flashkeyexists.html) is used to check if a specific key exists. So it would\
make sense to make use of that function in the code listed above to avoid\
outputting an empty `<p>` tag on requests where the Flash is empty.\
( [flash()](https://wheels.dev/api/v3.0.0/controller.flash.html) will return an empty string when the specified key does not\
exist.)

Check out the [Controller > Flash Functions](https://wheels.dev/api/v3.0.0/) section in the API listing of all the functions that deal with the Flash.

#### Wholesale Flash Handling with [flashMessages()](https://wheels.dev/api/v3.0.0/controller.flashmessages.html)

Throw the [flashIsEmpty()](https://wheels.dev/api/v3.0.0/controller.set.html) function into the mix, and you might find\
yourself writing code across your Wheels projects that looks something like\
this:&#x20;

```html
<cfoutput>

<cfif NOT flashIsEmpty()>
    <div id="flash-messages">
        <cfif flashKeyExists("error")>
            <p class="errorMessage">
                #flash("error")#
            </p>
        </cfif>
        <cfif flashKeyExists("success")>
            <p class="successMessage">
                #flash("success")#
            </p>
        </cfif>
    </div>
</cfif>

</cfoutput>
```

All of that above code can be replaced with a single call to the [flashMessages()](https://wheels.dev/api/v3.0.0/controller.flashmessages.html) function:

```html
<cfoutput>
#flashMessages()#
</cfoutput>
```

Whenever any value is inserted into the Flash, [flashMessages()](https://wheels.dev/api/v3.0.0/controller.flashmessages.html) will\
display it similarly to the complex example above, with `class` attributes set\
similarly (`errorMessage` for the `error` key and `successMessage` for the\
`success` key).

You can also use [flashMessages()](https://wheels.dev/api/v3.0.0/controller.flashmessages.html)'s `key/keys` argument to limit its reach\
to a list of given keys. Let's say that we only want our layout to show messages\
for the `alert` key but not for the `error` or `success` keys (or any other for\
that matter). We would write our call like so:

```html
<cfoutput>
#flashMessages(key="alert")#
</cfoutput>
```

Just keep in mind that this approach isn't as flexible, so if you need to\
customize the markup of the messages beyond [flashMessages()](https://wheels.dev/api/v3.0.0/controller.flashmessages.html)'s\
capabilities, you should revert back to using [flashIsEmpty()](https://wheels.dev/api/v3.0.0/controller.flashisempty.html),\
[flash()](https://wheels.dev/api/v3.0.0/controller.flash.html), and other related functions manually.

### Flash Storage Options

Earlier, we mentioned that the data for the Flash is stored in either the\
`cookie` or the `session` scope. You can find out where Wheels stores the Flash\
data in your application by outputting `get("flashStorage")`. If you have\
session management enabled in your application, Wheels will default to storing\
the Flash in the `session` scope. Otherwise, it will store it in a cookie on the\
user's computer.

You can override this setting in the same way that you override other Wheels\
settings by running the [set()](https://wheels.dev/api/v3.0.0/controller.set.html) function like this:

```javascript
// In `/config/settings.cfm` or another `settings.cfm` file within the `config` subfolders
set(flashStorage="session");
```

Note: Before you set Wheels to use the `session` scope, you need to make sure\
that session management is enabled. To enable it, all you need to do is add\
`this.SessionManagement = true` to the `/config/app.cfm` file.

#### Changing Flash Storage Dynamically During a Request

From Wheels 3.0, you now have the ability to dynamically change the flash storage\
during the lifecycle of a controller or request or the complete application using\
the `setFlashStorage()` function.

This can be helpful if you need to switch between using session-based or\
cookie-based flash storage at runtime depending on the context of the request.

```javascript
// Inside your controller action
setFlashStorage("cookie");
```

By default, it changes the storage for the current controller only. However,\
if you want to change it globally for all subsequent requests (until changed\
again), you can pass a second argument `setGlobally=true`:

```javascript
// Change globally for the entire application
setFlashStorage("session", true);
```

The storage argument accepts only `session` or `cookie`. If any other value is\
passed, Wheels will simply ignore the change (no error will be thrown).
Always make sure to pass a valid storage type to avoid unexpected behavior.

Note: Be careful when changing flash storage dynamically during requests,\
as it will change the entire application's flash scope depending on the settings\
and this may result in logical errors depending on your flash settings,\
especially if your application relies heavily on a consistent flash\
storage mechanism across multiple requests or clusters.

### Choosing a Storage Method

So what storage option should you choose? Well, to be honest, it doesn't really\
matter that much, so we recommend you just go with the default setting. If\
you're a control freak and always want to use the optimal setting, here are some\
considerations.

* Although the Flash data is deserialized before stored in a cookie (making it\
  possible to store complex values), you need to remember that a cookie is not the\
  best place to store data that requires a lot of space.
* If you run multiple ColdFusion servers in a clustered environment and use\
  session-based Flash storage, users might experience a loss of their Flash\
  variables as their request gets passed to other servers.
* Using cookies is, generally speaking, less secure than using the `session`\
  scope. Users could open their cookie file up and manually change its value.\
  Sessions are stored on the server, out of users' reach.

### Appending to, rather than replacing the flash

From Wheels 2.1, you can now change the default flash behavior to append to an existing key, rather than directly replacing it. To turn on this behavior, add `set(flashAppend=true)` to you `/config/settings.cfm` file.

An example of where this might be useful:

```javascript
// In your controller
if( thingOneHappened ){
  flashInsert(info="Thing One Happened");
}
if( thingTwoHappened ){
  flashInsert(info="Thing Two Happened");
}
```

Which, when output via `flashMessages()` would render:

```html
<div class=""flash-messages"">
  <p class=""info-message"">Thing One Happened</p>
  <p class=""info-message"">Thing Two Happened</p>
</div>
```

With `set(flashAppend=true)`, you can also directly pass in an array of strings like so:

```javascript
msgs=[
   "Thing One Happened", "Thing Two Happened"
];
flashInsert(info=msgs);
```

### Disabling the Flash Cookie

In `2.2` upwards:

There are certain circumstances where you might not be using the flash: for example, if you have wheels setup as a stateless API (perhaps in a cluster behind a load balancer) where you're using tokens vs sessions. In this circumstance, you've probably turned off session management, which only leaves `cookie` as a viable route. But if set to `cookie`, you always get `Set-Cookie` being returned, which is unnecessary.

In wheels 2.2 you can now `set(flashStorage = "none")` which will prevent the creation of the cookie, and also not try and write to a session.
