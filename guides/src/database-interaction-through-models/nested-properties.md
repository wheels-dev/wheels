---
description: Save data in associated model objects through the parent.
---

# Nested Properties

When you're starting out as a Wheels developer, you are probably amazed at the simplicity of a model's CRUD methods. But then it all gets quite a bit more complex when you need to update records in multiple database tables in a single transaction.

_Nested properties_ in Wheels makes this scenario dead simple. With a configuration using the [nestedProperties()](https://wheels.dev/api/v3.0.0/model.nestedproperties.html)function in your model's `config()` method, you can save changes to that model and its associated models in a single call with [save()](https://wheels.dev/api/v3.0.0/model.save.html), [create()](https://wheels.dev/api/v3.0.0/model.create.html), or [update()](https://wheels.dev/api/v3.0.0/model.update.html).

### One-to-One Relationships with Nested Properties

Consider a `user` model that has one `profile`:

{% code title="app/models/User.cfc" %}
```javascript
component extends="Model" {

  function config() {
        hasOne("profile");
        nestedProperties(associations="profile");
    }

}
```
{% endcode %}

By adding the call to [nestedProperties()](https://wheels.dev/api/v3.0.0/model.nestedproperties.html) in the model, you can create both the `user` object and the `profile` object in a single call to [create()](https://wheels.dev/api/v3.0.0/model.create.html).

### Setting up Data for the user Form in the Controller

First, in our controller, let's set the data needed for our form:

{% code title="app/controllers/User.cfc" %}
```javascript
// In app/controllers/User.cfc
function new() {
    var newProfile = model("profile").new();
    user = model("user").new(profile=newProfile);
}
```
{% endcode %}

Because our form will also expect an object called `profile` nested within the `user` object, we must create a new instance of it and set it as a property in the call to `user.new()`.

Also, because we don't intend on using the particular `newProfile` object set in the first line of the action, we can `var` scope it to clearly mark our intentions for its use.

If this were an `edit` action calling an existing object, our call would need to look similar to this:

{% code title="app/controllers/User.cfc" %}
```javascript
function edit() {
    user = model("user").findByKey(key=params.key, include="profile");
}
```
{% endcode %}

Because the form will also expect data set in the `profile` property, you must include that association in the finder call with the `include` argument.

### Building a Form for Posting Nested Properties

For this example, our form at `app/views/users/new.cfm` will end up looking like this:

{% code title="app/views/users/new.cfm" %}
```javascript
#startFormTag(action="create")#

    <!--- Data for user model --->
    #textField(label="First Name", objectName="user", property="firstName")#
    #textField(label="Last Name", objectName="user", property="lastName")#

    <!--- Data for associated profile model --->
    #textField(
        label="Twitter Handle",
        objectName="user",
        association="profile",
        property="twitterHandle"
    )#
    #textArea(
        label="Biography",
        objectName="user",
        association="profile",
        property="bio"
    )#

    <div>#submitTag(value="Create")#</div>

#endFormTag()#
```
{% endcode %}

Of note are the calls to form helpers for the `profile` model, which contain an extra argument for `association`. This argument is available for all object-based form helpers. By using the `association` argument, Wheels will name the form field in such a way that the properties for the profile will be nested within an object in the `user` model.

Take a minute to read that last statement again. OK, let's move on to the action that handles the form submission.

### Saving the Object and Its Nested Properties

You may be surprised to find out that our standard `create` action does not change at all from what you're used to.

{% code title="app/controllers/Users.cfc" %}
```javascript
function create() {
    user = model("user").new(params.user);
    if ( user.save() ) {
        flashInsert(success="The user was created successfully.");
        redirectTo(controller=params.controller);
    } else {
        renderView(action="new");
    }
}
```
{% endcode %}

When calling `user.save()` in the example above, Wheels takes care of the following:

* Saves the data passed into the `user` model.
* Sets a property on `user` called profile with the `profile` data stored in an object.
* Saves the data passed into that `profile` model.
* Wraps all calls in a transaction in case validations on any of the objects fail or something wrong happens with the database.

For the `edit` scenario, this is what our `update` action would look like (which is very similar to `create`):

{% code title="app/controllers/Users.cfc" %}
```javascript
function update() {
    user = model("user").findByKey(params.user.id);
    if ( user.update(params.user) ) {
        flashInsert(success="The user was updated successfully.");
        redirectTo(action="edit");
    } else {
        renderView(action="edit");
    }
}
```
{% endcode %}

### One-to-Many Relationships with Nested Properties

Nested properties work with one-to-many associations as well, except now the nested properties will contain an array of objects instead of a single one. We know that one `user` can have many `addresses`. Furthermore, we know that each `user` has only one `profile`.&#x20;

In the `user` model, let's add an association called `addresses` and also enable it as nested properties.

{% code title="app/models/User.cfc" %}
```javascript
component extends="Model" {

 function config() {
        hasOne("profile");
        hasMany("addresses");
        nestedProperties(
            associations="profile,addresses",
            allowDelete=true
        );
    }

}
```
{% endcode %}

In this example, we have added the `addresses` association to the call to [nestedProperties()](https://wheels.dev/api/v3.0.0/model.nestedproperties.html).

The `addresses` table contains a foreign key to the `Users` table called `userid`, Now in the `addresses` model, let's associate it with its parent `User` and also enable it as nested properties.

{% code title="app/models/Address.cfc" %}
```javascript
component extends="Model" {

 function config() {
        belongsTo("User");
        nestedProperties(
            associations="User",
            allowDelete=true
        );
    }

}
```
{% endcode %}

### Setting up Data for the user Form in the Controller

Setting up data for the form is similar to the one-to-one scenario, but this time the form will expect an array of objects for the nested properties instead of a single object.

In this example, we'll just put one new `address` in the array.

{% code title="app/controllers/Users.cfc" %}
```javascript
function new() {
    var newAddresses = [ model("address").new() ];
    user = model("user").new(addresses=newAddresses);
}
```
{% endcode %}

In the `edit` scenario, we just need to remember to call the `include` argument to include the array of addresses saved for the particular `user`:

{% code title="app/controllers/Users.cfc" %}
```javascript
function edit() {
    user = model("user").findByKey(key=params.key, include="addresses");
}
```
{% endcode %}

### Building the Form for the One-to-Many Association

This time, we'll add a section for addresses on our form:

{% code title="app/views/users/_form.cfm" %}
```javascript
#startFormTag(action="create")#

    <!--- Data for `user` model --->
    <fieldset>
        <legend>User</legend>

        #textField(label="First Name", objectName="user", property="firstName")#
        #textField(label="Last Name", objectName="user", property="lastName")#
    </fieldset>

    <!--- Data for `address` models --->
    <fieldset>
        <legend>Addresses</legend>

        <div id="addresses">
            #includePartial(user.addresses)#
        </div>
    </fieldset>

    <div>#submitTag(value="Create")#</div>

#endFormTag()#
```
{% endcode %}

In this case, you'll see that the form for addresses is broken into a partial. (See the chapter on Partials for more details.) Let's take a look at that partial.

### The \_address Partial

Here is the code for the partial at `app/views/users/_address.cfm`. Wheels will loop through each `address` in your nested properties and display this piece of code for each one.

{% code title="app/views/users/_address.cfm" %}
```javascript
<div class="address">
    #textField(
        label="Street",
        objectName="user",
        association="addresses",
        position=arguments.current,
        property="address1"
    )#
    #textField(
        label="City",
        objectName="user",
        association="addresses",
        position=arguments.current,
        property="city"
    )#
    #textField(
        label="State",
        objectName="user",
        association="addresses",
        position=arguments.current,
        property="state"
    )#
    #textField(
        label="Zip",
        objectName="user",
        association="addresses",
        position=arguments.current,
        property="zip"
    )#
</div>
```
{% endcode %}

Because there can be multiple addresses on the form, the form helpers require an additional argument for `position`. Without having a unique position identifier for each `address`, Wheels would have no way of understanding which `state` field matches with which particular `address`, for example.

Here, we're passing a value of `arguments.current` for `position`. This value is set automatically by Wheels for each iteration through the loop of `addresses`.

### Auto-saving a Collection of Child Objects

Even with a complex form with a number of child objects, Wheels will save all of the data through its parent's [save()](https://wheels.dev/api/v3.0.0/model.save.html), [update()](https://wheels.dev/api/v3.0.0/model.update.html), or [create()](https://wheels.dev/api/v3.0.0/model.create.html) methods.

Basically, your typical code to save the `user` and its `addresses` is exactly the same as the code demonstrated in the _Saving the Object and Its Nested Properties_ section earlier in this chapter.

Writing the action to save the data is clearly the easiest part of this process!

### Transactions are Included by Default

As mentioned earlier, Wheels will automatically wrap your database operations for nested properties in a transaction. That way if something goes wrong with any of the operations, the transaction will rollback, and you won't end up with incomplete saves.

See the chapter on [Transactions](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/database-interaction-through-models/transactions) for more details.

### Many-to-Many Relationships with Nested Properties

We all enter the scenario where we have "join tables" where we need to associate models in a many-to-many fashion. Wheels makes this pairing of entities simple with some form helpers.

Consider the many-to-many associations related to `customers, publications`, and `subscriptions`, straight from the [Associations](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/database-interaction-through-models/associations) chapter.

```javascript
//  app/models/Customer.cfc
component extends="Model" {

    public function config() {
        hasMany(name="subscriptions", shortcut="publications");
    }

}
//  app/models/Publication.cfc
component extends="Model" {

    public function config() {
        hasMany("subscriptions");
    }

}
//  app/models/Subscription.cfc
component extends="Model" {

    public function config() {
        belongsTo("customer");
        belongsTo("publication");
    }

}
```

When it's time to save `customer`s' subscriptions in the `subscriptions` join table, one approach is to loop through data submitted by [checkBoxTag()](https://wheels.dev/api/v3.0.0/controller.checkboxtag.html)s from your form, populate `subscription` model objects with the data, and call [save()](https://wheels.dev/api/v3.0.0/model.save.html). This approach is valid, but it is quite cumbersome. Fortunately, there is a simpler way.

### Setting up the Nested Properties in the Model

Here is how we would set up the nested properties in the `customer` model for this example:

{% code title="app/models/Customer.cfc" %}
```javascript
component extends="Model" {

    public function config() {
        //  Associations
        hasMany(name="subscriptions", shortcut="publications");
        //  Nested properties
        nestedProperties(
            associations="subscriptions",
            allowDelete=true
        );
    }

}
```
{% endcode %}

### Setting up Data for the customer Form in the Controller

Let's define the data needed in an `edit` action in the controller at `app/controllers/Customers.cfc`.

{% code title="app/controllers/Customers.cfc" %}
```javascript
function edit() {
    customer = model("customer").findByKey(
        key=params.key,
        include="subscriptions"
    );
    publications = model("publication").findAll(order="title");
}
```
{% endcode %}

For the view, we need to pull the `customer` with its associated `subscriptions` included with the `include` argument. We also need all of the `publication`s in the system for the user to choose from.

### Building the Many-to-Many Form

We can now build a series of check boxes that will allow the end user choose which `publications` to assign to the `customer`.

The view template at `app/views/customers/edit.cfm` is where the magic happens. In this view, we will have a form for editing the `customer` and check boxes for selecting the `customer`'s `subscriptions`.

{% code title="app/views/customers/edit.cfm" %}
```javascript
<cfparam name="customer">
<cfparam name="publications" type="query">

<cfoutput>

#startFormTag(action="update")#

<fieldset>
    <legend>Customer</legend>

    #textField(
        label="First Name",
        objectName="customer",
        property="firstName"
    )#
    #textField(
        label="Last Name",
        objectName="customer",
        property="lastName"
    )#
</fieldset>

<fieldset>
    <legend>Subscriptions</legend>

    <cfloop query="publications">
        #hasManyCheckBox(
            label=publications.title,
            objectName="customer",
            association="subscriptions",
            keys="#customer.key()#,#publications.id#"
        )#
    </cfloop>
</fieldset>

<div>
    #hiddenField(objectName="customer", value="id")#
    #submitTag()#
</div>

#endFormTag()#

</cfoutput>
```
{% endcode %}

The main point of interest in this example is the `<fieldset>` for Subscriptions, which loops through the query of `publications` and uses the [hasManyCheckBox()](https://wheels.dev/api/v3.0.0/controller.hasmanycheckbox.html) form helper. This helper is similar to [checkBox()](https://wheels.dev/api/v3.0.0/controller.checkbox.html) and [checkBoxTag()](https://wheels.dev/api/v3.0.0/controller.checkboxtag.html), but it is specifically designed for building form data related by associations. (Note that [checkBox()](https://wheels.dev/api/v3.0.0/controller.checkbox.html) is primarily designed for columns in your table that store a single `true/false` value, so that is the big difference.)

Notice that the `objectName` argument passed to [hasManyCheckBox()](https://wheels.dev/api/v3.0.0/controller.hasmanycheckbox.html) is the parent `customer` object and the `associations` argument contains the name of the related association. Wheels will build a form variable named in a way that the `customer` object is automatically bound to the `subscriptions` association.

The `keys` argument accepts the foreign keys that should be associated together in the `subscriptions` join table. Note that these keys should be listed in the order that they appear in the database table. In this example, the `subscriptions` table in the database contains a composite primary key with columns called `customerid` and `publicationid`, in that order.

### How the Form Submission Works

Handling the form submission is the most powerful part of the process, but like all other nested properties scenarios, it involves no extra effort on your part.

You'll notice that this example `update` action is fairly standard for a Wheels application:

{% code title="app/controllers/Customers.cfc" %}
```javascript
function update() {
    //  Load customer object
    customer = model("customer").findByKey(params.customer.id);
    /*  If update is successful, generate success message
        and redirect back to edit screen */
    if ( customer.update(params.customer) ) {
        redirectTo(
            action="edit",
            key=customer.id,
            success="#customer.firstName# #customer.lastName# record updated successfully."
        );
        //  If update fails, show form with errors 
    } else {
        renderView(action="edit");
    }
}
```
{% endcode %}

In fact, there is nothing special about this. But with the nested properties defined in the model, Wheels handles quite a bit when you save the `parent` customer object:

* Wheels will update the `customers` table with any changes submitted in the Customers `<fieldset>`.
* Wheels will add and remove records in the `subscriptions` table depending on which check boxes are selected by the user in the Subscriptions `<fieldset>`.
* All of these database queries will be wrapped in a [Transaction](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/database-interaction-through-models/transactions) . If any of the above updates don't pass validation or if the database queries fail, the transaction will roll back.
