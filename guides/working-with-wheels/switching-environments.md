---
description: Environments that match your development stages.
---

# Switching Environments

Wheels allows you to set up different _environments_ that match stages in your development cycle. That way you can configure different values that match what services to call and how your app behaves based on where you are in your development.

The **Development** environment is the most convenient one to use as you start building your application because it does not cache any data. Therefore, if you make any changes to your controllers and actions, for example, it will immediately be picked up by Wheels.

Other environment modes cache this information in order to speed up your application as much as possible. Making changes to the database in these most modes will cause Wheels to throw an error. (Although that can be avoided with a `reload` call. More on that later.)

The fastest environment mode in terms of page load time is the **Production** mode. This is what you should set your application to run in before you launch your website.

By default, all new applications will start in the Development environment which is middle-of-the-road in terms of convenience versus speed.

### The 4 Environment Modes

Besides the 2 environments mentioned above, there are 2 more. Let's go through them all one by one so you can see the differences between them and choose the most appropriate one given your current stage of development.

**Development**

* Shows friendly Wheels specific errors as well as regular ColdFusion errors on screen.
* Does not email you when an error is encountered.
* Caches controller and model initialization (the `config()` methods).
* Caches the database schema.
* Caches routes.
* Caches image information.

**Production**

* Caches everything that the Development mode caches.
* Activates all developer controlled caching (actions, pages, queries and partials).
* Shows your custom error page when an error is encountered.
* Shows your custom 404 page when a controller or action is not found.
* Sends an email to you when an error is encountered.

**Testing**

* Same caching settings as the Production mode but using the error handling of the Development mode. (Good for testing an application at its true speed while still getting errors reported on screen.)

**Maintenance**

* Shows your custom maintenance page unless the requesting IP address or user agent is in the exception list (set by calling `set(ipExceptions="127.0.0.1")` in `app/config/settings.cfm` or passed along in the URL as `except=127.0.0.1`, or as `except=myuseragentstring` to match against the user agent instead. Please note that if passing an exception on the URL using the `except` parameter, you must also provide the `password` parameter if a reload password has been defined. This eliminates the possibility of a rogue actor breaking out of maintenance mode by simply adding an `except` to the URL.

This environment mode comes in handy when you want to briefly take your website offline to upload changes or modify databases on production servers.

### How to Switch Modes

You can change the current environment by modifying the `app/config/environment.cfm` file. After you've modified it, you need to either restart the ColdFusion service or issue a `reload` request. (See below for more info.)

**The reload Request**&#x20;

Issuing a reload request is the easiest way to go from one environment to another. It's done by passing in reload as a parameter in the URL, like this:

{% code title="HTTP" %}
```
http://www.mysite.com/?reload=true
```
{% endcode %}

This tells Wheels to reload the entire framework (it will also run your code in the `app/events/onapplicationstart.cfm`file), thus picking up any changes made in the `app/config/environment.cfm` file.

**Lazy Reloading**&#x20;

There's also a shortcut for lazy developers who don't want to change this file at all. To use it, just issue the reload request like this instead:

{% code title="HTTP" %}
```
http://www.mysite.com/?reload=testing
```
{% endcode %}

This will make Wheels skip your `app/config/environment.cfm` file and just use the URL value instead (`testing`, in this case).

**Password-Protected Reloads**&#x20;

For added protection, you can set the `reloadPassword` variable in `app/config/settings.cfm`. When set, a reload request will only be honored when the correct password is also supplied, like this:

{% code title="HTTP" %}
```
http://www.mysite.com/?reload=testing&password=mypass
```
{% endcode %}

{% hint style="warning" %}
#### Don't forget your reload password in production

You really don't want random users hitting ?reload=development on a production server, as it could potentially expose data about your application and error messages. Always set a reload password!
{% endhint %}

### Disabling Environment Switching

If you're deploying to a container based environment, or one that you _know_ you'll never want to switch out of production mode, you can disable URL based environment switching completely via:\
`set(allowEnvironmentSwitchViaUrl = false);`

This is just an additional check to ensure that your production mode acts in the way you expect! Application reloading is still allowed, but the configuration can not be altered.

## IP-Based Debug Access in Non-Development Environments

By default, Wheels only enables the debug GUI (wheels interface) and debug information in the development environment. However, there may be situations where you need access to these debugging tools in other environments like testing, production, or maintenance - but only for specific IP addresses.

Wheels provides IP-based access control for the debug GUI and debug information through two configuration settings:

### Configuration Settings

Add these settings to your environment-specific configuration files (e.g., `app/config/production/settings.cfm`):

```cfml
// Define allowed IP addresses that can access debug features
set(debugAccessIPs = ["203.0.113.45", "198.51.100.22", "127.0.0.1"]);

// Enable IP-based debug access control
set(allowIPBasedDebugAccess = true);
```

### How It Works

When these settings are configured:

1. In the development environment, the debug GUI is always accessible regardless of IP address.
2. In other environments (testing, production), the debug GUI and debug information will only be enabled for requests coming from IP addresses listed in the `debugAccessIPs` array.
3. If a request comes from an IP address not in the list, the debug GUI and debug information remain disabled, maintaining security in production environments.

### Example Configuration

Here's a typical setup for different environments:

**Development** (`app/config/development/settings.cfm`):
```cfml
// Debug GUI is enabled by default in development, no additional settings needed
```

**Testing** (`app/config/testing/settings.cfm`):
```cfml
set(debugAccessIPs = ["127.0.0.1", "192.168.1.100"]);
set(allowIPBasedDebugAccess = true);
```

**Production** (`app/config/production/settings.cfm`):
```cfml
set(debugAccessIPs = ["10.0.0.5"]); // Only specific admin IPs
set(allowIPBasedDebugAccess = true);
```

This feature allows administrators to access debugging tools in production or other environments while keeping them secure from regular users, providing a flexible way to troubleshoot issues in all environments without compromising security.
