# Nesting Controllers

With the new routing system in Wheels 2.x, there are lots of nice features which allow for better code organization. One of these is the ability to nest controllers into folders using the `namespace()` method in our `mapper()` call.

For example, we may have a whole "Admin" section, where for each endpoint, we need to check some permissions, and possibly load some default data. Let's say we have a `Users` controller which provides standard CRUD operations.

{% code title="/config/routes.cfm" %}
```javascript
.mapper()
  .namespace("admin")
    .resources("users")
  .end()
.end()
```
{% endcode %}

This will automatically look for the `Users.cfc` controller in `/app/controllers/admin/`.

By default, all your controllers `extend="Controller"`, but with a nested controller, we need to change this, as the main `Controller.cfc` isn't at the same folder level.

### A Handy Mapping

We've added a new mapping in 3.x, called `app`; This mapping will correspond to the `app` folder, so in our `Users.cfc` we now have two options - extend the core `Controller.cfc` via the app mapping, or perhaps extend another component (possibly `Admin.cfc`) which extends the core Controller instead.

{% code title="/app/controllers/admin/Users.cfc" %}
```javascript
component extends="app.controllers.Controller" {

  function config(){
    super.config();
  }

}
```
{% endcode %}

In the above example, we're using the `app` mapping to "go to" the `app` folder, and then look for a folder called `controllers`, and within that, our main `Controller.cfc`.

Our `super.config()` call will then run the `config()` function in our base Controller.

We could of course have the following too (just for completeness sake):

{% code title="File system" %}
```
/app/
  /controllers/
    /admin/
      - Admin.cfc
      - Users.cfc
    /public/
      - etc.
```
{% endcode %}

And then add the `app.controllers.Controller` mapping to `Admin.cfc`, and the `extends="Admin"` in the `Users.cfc`.

### Not just controllers...

Of course, we can _extend_ this concept (ha!) to Models too. However, this is either limited to tableless models, or models where you implicitly specify the `table()` call. As Wheels will look for the tablename dependent on the model file location, it'll get confused if in a sub-directory.

{% code title="/app/models/auth/LDAP.cfc" %}
```javascript
component extends="app.models.Model"
{
    function config() {
        table(false);
    }
    function save(){
    }
}
```
{% endcode %}

It also potentially makes your `model()` calls more complex, as you need to specify the model name in dot notation:

{% code title="Example nested model call" %}
```javascript
// Example for "LDAP.cfc" in "/models/auth"
myNewLDAPModel=model("auth.LDAP").new();
```
{% endcode %}
