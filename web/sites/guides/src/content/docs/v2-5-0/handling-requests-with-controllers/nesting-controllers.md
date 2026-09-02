---
title: Nesting Controllers
---
# Nesting Controllers

With the new routing system in CFWheels 2.x, there are lots of nice features which allow for better code organization. One of these is the ability to nest controllers into folders using the `namespace()` method in our `mapper()` call.

For example, we may have a whole "Admin" section, where for each endpoint, we need to check some permissions, and possibly load some default data. Let's say we have a `Users` controller which provides standard CRUD operations.

```javascript title="config/routes.cfm"
.mapper()
  .namespace("admin")
    .resources("users")
  .end()
.end()
```

This will automatically look for the `Users.cfc` controller in `controllers/admin/`.

By default, all your controllers `extend="Controller"`, but with a nested controller, we need to change this, as the main `Controller.cfc` isn't at the same folder level.

### A Handy Mapping

We've added a new mapping in 2.x, called `app`; This mapping will always correspond to your site root, so in our `Users.cfc` we now have two options - extend the core `Controller.cfc` via the app mapping, or perhaps extend another component (possibly `Admin.cfc`) which extends the core Controller instead.

```javascript title="admin/Users.cfc"
component extends="app.controllers.Controller" {

  function config(){
    super.config();
  }

}
```

In the above example, we're using the `app` mapping to "go to" the site root, and then look for a folder called `controllers`, and within that, our main `Controller.cfc`.

Our `super.config()` call will then run the `config()` function in our base Controller.

We could of course have the following too (just for completeness sake):

```txt title="File system"
/controllers/
  /admin/
    - Admin.cfc
    - Users.cfc
  /public/
    - etc.
```

And then add the `app.controllers.Controller` mapping to `Admin.cfc`, and the `extends="Admin"` in the `Users.cfc`.

### Not just controllers...

Of course, we can _extend_ this concept (ha!) to Models too. However, this is either limited to tableless models, or models where you implicitly specify the `table()` call. As Wheels will look for the tablename dependent on the model file location, it'll get confused if in a sub-directory.

```javascript title="models/auth/LDAP.cfc"
component extends="app.models.Model"
{
    function config() {
        table(false);
    }
    function save(){
    }
}
```

It also potentially makes your `model()` calls more complex, as you need to specify the model name in dot notation:

```javascript title="Example nested model call"
// Example for "LDAP.cfc" in "/models/auth"
myNewLDAPModel=model("auth.LDAP").new();
```
