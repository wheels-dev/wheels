---
description: Environments that match your development stages.
---

# Switching Environments

Wheels allows you to set up different _environments_ that match stages in your development cycle. That way you can configure different values that match what services to call and how your app behaves based on where you are in your development.

The **Development** environment is the most convenient one to use as you start building your application because it does not cache any data. Therefore, if you make any changes to your controllers and actions, for example, it will immediately be picked up by Wheels.

Other environment modes cache this information in order to speed up your application as much as possible. Making changes to the database in most of these modes will cause Wheels to throw an error. (Although that can be avoided with a `reload` call. More on that later.)

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

* Shows your custom maintenance page unless the requesting IP address or user agent is in the exception list (set by calling `set(ipExceptions="127.0.0.1")` in `/config/settings.cfm` or passed along in the URL as `except=127.0.0.1`, or as `except=myuseragentstring` to match against the user agent instead. Please note that if passing an exception on the URL using the `except` parameter, you must also provide the `password` parameter if a reload password has been defined. This eliminates the possibility of a rogue actor breaking out of maintenance mode by simply adding an `except` to the URL.

This environment mode comes in handy when you want to briefly take your website offline to upload changes or modify databases on production servers.

### How to Switch Modes

Wheels provides multiple ways to switch between environments. Choose the method that best fits your workflow:

## Method 1: Using the CLI Command (Recommended)

The easiest and most reliable way to switch environments is using the Wheels CLI command:

```cfml
wheels env switch production
```

This command will:
1. Update the `set(environment="...")` setting in `/config/environment.cfm`
2. Automatically reload the application to apply the changes
3. Validate that the target environment exists before switching

**Examples:**
```cfml
# Switch to production environment
wheels env switch production

# Switch to testing environment
wheels env switch testing

# Switch to development environment
wheels env switch development
```

## Method 2: Manual File Editing

If you prefer not to use the CLI command, you can manually change the environment by editing the `/config/environment.cfm` file:

```cfml
// /config/environment.cfm
<cfscript>
    // Change this value to your desired environment
    set(environment="production");
</cfscript>
```

**Available environment values:**
- `development` - For local development with full debugging
- `production` - For live production servers with caching enabled
- `testing` - For automated testing with production-like caching
- `maintenance` - For temporarily taking your site offline

After manually editing the file, you **must** reload the application using one of these methods:

### Option A: URL-Based Reload

Issue a reload request by passing `reload` as a URL parameter:

```
http://www.mysite.com/?reload=true
```

This tells Wheels to reload the entire framework (including your `/app/events/onapplicationstart.cfm` file), picking up any changes made in the `/config/environment.cfm` file.

### Option B: Lazy URL Reloading

For quick testing, you can temporarily switch environments without editing any files:

```
http://www.mysite.com/?reload=testing
```

This will make Wheels skip your `/config/environment.cfm` file and use the URL value instead (`testing` in this case). **Note:** This is temporary and will revert to the configured environment on the next application restart.

### Option C: Server Restart

Alternatively, you can restart the ColdFusion/Lucee service to reload the application and apply environment changes.

## Password-Protected Reloads

When using URL-based reload methods (Options A and B above), you should add protection by setting the `reloadPassword` variable in `/config/settings.cfm`:

```cfml
// /config/settings.cfm
<cfscript>
    set(reloadPassword="mySecurePassword");
</cfscript>
```

When a password is set, reload requests must include the password parameter:

```
http://www.mysite.com/?reload=true&password=mySecurePassword
http://www.mysite.com/?reload=testing&password=mySecurePassword
```

> **⚠️ WARNING: Always use a reload password in production**
>
> You really don't want random users hitting `?reload=development` on a production server, as it could expose sensitive data about your application and error messages. **Always set a reload password for production environments!**

**Note:** The `wheels env switch` CLI command bypasses URL-based reloads and directly updates the configuration file, so it's not affected by the reload password setting.

### Disabling Environment Switching

If you're deploying to a container based environment, or one that you _know_ you'll never want to switch out of production mode, you can disable URL based environment switching completely via:\
`set(allowEnvironmentSwitchViaUrl = false);`

This is just an additional check to ensure that your production mode acts in the way you expect! Application reloading is still allowed, but the configuration can not be altered.

## IP-Based Debug Access in Non-Development Environments

By default, Wheels only enables the debug GUI (wheels interface) and debug information in the development environment. However, there may be situations where you need access to these debugging tools in other environments like testing, production, or maintenance - but only for specific IP addresses.

Wheels provides IP-based access control for the debug GUI and debug information through two configuration settings:

### Configuration Settings

Add these settings to your environment-specific configuration files (e.g., `/config/production/settings.cfm`):

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

**Development** (`/config/development/settings.cfm`):
```cfml
// Debug GUI is enabled by default in development, no additional settings needed
```

**Testing** (`/config/testing/settings.cfm`):
```cfml
set(debugAccessIPs = ["127.0.0.1", "192.168.1.100"]);
set(allowIPBasedDebugAccess = true);
```

**Production** (`/config/production/settings.cfm`):
```cfml
set(debugAccessIPs = ["10.0.0.5"]); // Only specific admin IPs
set(allowIPBasedDebugAccess = true);
```

This feature allows administrators to access debugging tools in production or other environments while keeping them secure from regular users, providing a flexible way to troubleshoot issues in all environments without compromising security.
