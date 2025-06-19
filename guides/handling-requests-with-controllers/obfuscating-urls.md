---
description: Hide your primary key values from nosy users.
---

# Obfuscating URLs

The Wheels convention of using an auto-incrementing integer value as the primary key in your database tables will lead to a lot of URLs on your website exposing this value. Using the built-in URL obfuscation functionality in Wheels, you can hide this value from nosy users.

### What URL Obfuscation Does

When URL obfuscation is turned off (which is the default setting in Wheels), this is how a lot of your URLs will end up looking:

{% code title="HTTP" %}
```
http://localhost/user/profile/99
```
{% endcode %}

Here, `99` is the primary key value of a record in your users table.

After enabling URL obfuscation, this is how those URLs will look instead:

{% code title="HTTP" %}
```
http://localhost/user/profile/b7ab9a50
```
{% endcode %}

The value `99` has now been obfuscated by Wheels to `b7ab9a50`. This makes it harder for nosy users to substitute the value to see how many records are in your users table, to name just one example.

### How to Use It

To turn on URL obfuscation, all you have to do is call `set(obfuscateURLs=true)` in the `app/config/settings.cfm` file.

Once you do that, Wheels will handle everything else. Obviously, the main things Wheels does is obfuscate the primary key value when using the [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) function and deobfuscate it on the receiving end. Wheels will also obfuscate all other params sent in to [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) as well as any value in a form sent using a get request.

In some circumstances, you will need to obfuscate and deobfuscate values yourself if you link to pages without using the [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) function, for example. In these cases, you can use the `obfuscateParam()` and `deObfuscateParam()`functions to do the job for you.

### Is This Really Secure?

No, this is not meant to add a high level of security to your application. It just obfuscates the values, making casual observation harder. It does not encrypt values, so keep that in mind when using this approach.

For instance, unless you specify it in your `app/config/routes.cfm` file, you can still directly access numeric keys in the URL, e.g. `/users/view/99`; However, there is a small work around you can implement to prevent this at least, using the routes `constraints` argument.

```javascript
mapper()
  .resources(name = "users", constraints = { key = "\w+\d+" } )
  .root( to="home##index", method="get")
.end();
```

This uses Regex to ensure the `params.key` argument is an alpha numeric key and not just purely numeric: otherwise the route won't match.
