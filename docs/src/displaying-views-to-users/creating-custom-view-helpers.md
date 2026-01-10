---
description: Clean up your views by moving common functionality into helper functions.
---

# Creating Custom View Helpers

As you probably know already, Wheels gives you a lot of helper functions that you can use in your view pages.

Perhaps what you didn't know was that you can also create your own view helper functions and have Wheels automatically make them available to you. To do this, you store your UDFs (User Defined Functions) in different controller-level helper files.

### The /app/views/helpers.cfm File

Once a UDF is placed in this file, it will be available for use in all your views.

Alternatively, if you only need a set of functions in a specific controller of your application, you can make them controller-specific. This is done by placing a `helpers.cfm` file inside the controller's view folder.

So if we wanted a set of helpers to generally only be available for your users controller, you would store the UDFs in this file:

```javascript
/app/views/users/helpers.cfm
```

Any functions in that file will now only be included for the view pages of that specific controller.

### When _not_ to Use Helper Functions

Helper functions, together with the use of [Partials](https://wheels.dev/3.0.0/guides/displaying-views-to-users/partials), gives you a way to keep your code nice and DRY, but there are a few things to keep in mind as you work with them.

The `helpers.cfm` files are only meant to be used for views, hence the placement in the _**/app/views**_ folder.

If you need to share non-view functionality across controllers, then those should be placed in the parent controller file, i.e. `/app/controllers/Controller.cfc`. If you need helper type functionality within a **single** controller file, you can just add it as a function in that controller and make it private so that it can't be called as an action (and as a reminder to yourself of its general purpose as well).

The same applies to reusable model functionality: use the parent file, `/app/models/Model.cfc`. Private functions within your children models work well here, just like with controllers.

If you need to share a function globally across your entire application, regardless of which MVC layer that will be accessing it, then you can place it in the `/app/events/functions.cfm` file.

### The Difference Between Partials and Helpers

Both partials and helpers are there to assist you in keeping programmatic details out of your views as much as possible. Both do the job well, and which one you choose is just a matter of preference.

Generally speaking, it probably makes most sense to use partials when you're generating a lot of HTML and helpers when you're not.
