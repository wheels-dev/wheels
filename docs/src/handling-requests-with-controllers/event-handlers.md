---
description: Use the standard CFML application events through the framework.
---

# Event Handlers

Because the `Application.cfc` file is in the `public` folder of your Wheels site and it has the necessary framework initialization like `onApplicationStart`, `onRequestStart`, It uses [Wirebox](https://www.ortussolutions.com/products/wirebox) to initiailize the `core/src/wheels/Global.cfc`, which contains the initialization for controller and global functions like [model()](https://wheels.dev/api/v3.0.0/controller.model.html), you may wonder what the best way is to use CFML's onApplicationStart, onRequestStart, etc. functions.

While it's perfectly possible to add your code directly to the `/public/Application.cfc` or `core/src/wheels/Global.cfc` file, we certainly don't recommend it. If you add code in there, you both increase the risk of accidentally modifying how the framework functions, and you also make it a lot harder to upgrade to future versions of Wheels.

### Use the events Folder for Standard CFML Events

The general recommendation is to never touch any files in the wheels folder. OK, with that little warning out of the way, how does one go about using the CFML events?

The answer is to use the `/app/events` folder. There is a file in there for every single event that CFML triggers. So if you want some code executed on application start for example, just place your code in `onapplicationstart.cfm`, and Wheels will run it when your application starts.

### Wheels Includes Some Extra Bonus Events

If you look closely in the `events` folder, you will also notice that there are some custom files in there that do not match up with standard CFML events. The `onmaintenance.cfm` file is one example. Let's have a closer look at these.

**On Maintenance**

The `onmaintenance.cfm` file is included when Wheels is set to maintenance mode. After the file is included, `cfabort` is called by Wheels so no other code runs in this mode.

**On Error**

You can place a generic error message in the `onerror.cfm` file to be displayed to the users whenever your site throws an error.

If you need to access the error information here (for logging purposes, for example) it is available at `arguments.exception`.

**On Missing Template**

The `onmissingtemplate.cfm` file works in a similar way as the error file above, but it gets called when a controller or action in your application could not be found.

Note: If you want to make sure that all browsers show your custom 404 page you need to make it larger than 512 bytes in size. Google Chrome, for example, will display a friendly help page of its own when the 404 page is less than 512 bytes.

### Adding Functions

Sometimes it's useful to add functions right in the `Application.cfc` file to make them available to all templates. To achieve the same thing in Wheels, you can place your functions in `/app/global/functions.cfm`.

### Application Settings

Again, because there is no `Application.cfc` file for you to work with in Wheels, you have to find a suitable place to set application settings such as `SessionManagement`, `SessionTimeout, ScriptProtect, SetClientCookies`, and so on. These are usually set in the constructor area of an `Application.cfc` file. We recommend that you set them in the `/config/app.cfm` file instead.
