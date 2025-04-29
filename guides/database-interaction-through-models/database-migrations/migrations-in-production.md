---
description: Techniques for migrating your database in production
---

# Migrations in Production

Once you've created your migration files and committed your changes (you are all using source control - right?) you might be wondering about the different ways to migrate your database in a production environment.

### Manual Migrations via GUI

Probably one of the most common and basic deployment types is a standalone virtual machine, running ACF or Lucee, with a database server such as MySQL running on the same box. In this scenario, we could probably stick with the simplest option: there is after all, probably only one instance of the site running.

* Put the site into maintenance mode (this is always good practice when deploying new code)
* Load the internal Migration GUI, migrate your database. **Note:** Ensure your IP address is in the maintenance mode exclusion list: the debug footer may not be available, so make a note of the url string `?controller=wheels&action=wheels&view=migrate`
* Reload the application back into production mode

### Automatic Migrations

You may well have a more complicated setup, such as being behind a load balancer, or having dynamic instances of your application - such as AWS ElasticBeanstalk - where logging into the same instance isn't practical; it may be your application is an API where a request could get routed to any node in the cluster, or that "sticky" sessions aren't enabled.

This means running the migrations manually via GUI isn't a practical option - you might accidentally leave a node in the cluster in maintenance mode and not be able to easily return to it etc.

In this scenario, you could use the built-in `autoMigrateDatabase` setting: this will automatically migrate the database to the latest schema version when the application starts.

This would fire for each node on a cluster and would fire on each application restart - however, the overhead would be minimal (one additional database call).&#x20;

To activate this feature, just use `set(autoMigrateDatabase=true)` in your `app/config/production/settings.cfm` settings, to ensure it only fires in production mode.

### Programmatic Migrations

It might be that full automatic migrations aren't necessary, or undesirable for some reason. You could have a script which essentially replaces the GUI functions and call the migration methods manually.&#x20;

Please consult the internal documentation API reference under Configurations > Database Migrations for details of the various functions available to you.

### Further considerations with automatic migrations

If you are using automatic migrations, then you could lock down production mode even further. With Wheels 2.x there is more data available to development mode, such as the internal documentation, routing GUI and Migration GUI.

**Turn off environment switching**

You can force Wheels to remain in production via `set(allowEnvironmentSwitchViaUrl=false)` - this will disable `?reload=maintenance` style URLs where there is a configuration change, but simple reloading such as `?reload=true` will still work. This setting should be approached with caution, as once you've entered into a mode with this setting on, you can't then switch out of it.
