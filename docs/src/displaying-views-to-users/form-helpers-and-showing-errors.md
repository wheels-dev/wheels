---
description: >-
  Wheels ties your application's forms together with your model layer
  elegantly. With Wheels form conventions, you'll find yourself spending less
  time writing repetitive markup.
---

# Form Helpers and Showing Errors

The majority of applications are not all about back-end. There is a great deal of work to perform on the front-end as well. It can be argued that most of your users will think of the interface _as_ the application.

Wheels is here to take you to greener pastures with its form helper functions. Let's get visual with some code examples.

### Simple Example: The Old Way

Here is a simple form for editing a user profile. Normally, you would code your web form similarly to this:

{% code title="templates/base/src/app/views/profiles/edit.cfm" %}
```html
<cfoutput>

<form action="/profile" method="post">
    <div>
        <label for="firstName">First Name</label>
        <input id="firstName" name="firstName" value="#EncodeForHtml(profile.firstName)#">
    </div>

    <div>
        <label for="lastName">Last Name</label>
        <input id="lastName" name="lastName" value="#EncodeForHtml(profile.lastName)#">
    </div>

    <div>
        <label for="department">Department</label>
        <select id="department" name="departmentId">
            <cfloop query="departments">
                <option
                    value="#EncodeForHtml(departments.id)#"
                    <cfif profile.departmentId eq departments.id>
                        selected
                    </cfif>
                >#EncodeForHtml(departments.name)#</option>
            </cfloop>
        </select>
    </div>

    <div>
        <input type="submit" value="Save Changes">
    </div>
</form>

</cfoutput>
```
{% endcode %}

Then you would write a script for the form that validates the data submitted, handles interactions with the data source(s), and displays the form with errors that may happen as a result of user input. (And most of that code isn't even included in this example.)

We know that you are quite familiar with the drudgery of typing this sort of code over and over again. Let's not even mention the pain associated with debugging it or adding new fields and business logic!

### Making Life Easier: Wheels Form Helpers

The good news is that Wheels simplifies this quite a bit for you. At first, it looks a little different using these conventions. But you'll quickly see how it all ties together and saves you some serious time.

### Rewriting the Form with Wheels Conventions

Let's rewrite and then explain.

{% code title="templates/base/src/app/views/profiles/edit.cfm" %}
```html
<cfoutput>

#startFormTag(route="profile", method="patch")#
    #textField(
        label="First Name",
        objectName="profile",
        property="firstName",
        prependToLabel="<div>",
        append="</div>",
        labelPlacement="before"
    )#

    #textField(
        label="Last Name",
        objectName="profile",
        property="lastName",
        prependToLabel="<div>",
        append="</div>",
        labelPlacement="before"
    )#

    #select(
        label="Department",
        objectName="profile",
        property="departmentId",
        options=departments,
        prependToLabel="<div>",
        append="</div>",
        labelPlacement="before"
    )#

    <div>
        #submitTag()#
    </div>
#endFormTag()#

</cfoutput>
```
{% endcode %}

I know what you are thinking. 9 lines of code can't replace all that work, right? In fact, they do. The HTML output will be very nearly the same as the previous example. By using Wheels conventions, you are saving yourself a lot of key strokes and a great deal of time.

### Linking up the Form's Action with startFormTag

The first helper you'll notice in the Wheels-ified version of the form is [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startFormTag.html). This helper allows you to easily link up the form to the action that it's posting to in a secure way.

You'll need to configure the `route` and `method` arguments, depending on the route that you're sending the form to. Also, if the route expects any parameters, you must pass those in as arguments to startFormTag as well. If you haven't already, read up about routes in the [Routing](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing) chapter.

As we said, when linking a form to a route, there are 3 pieces of information that you will need to work with:

1. Route _name_
2. _Parameters_ that the route may expect
3. Request _method_ that the route requires

{% hint style="info" %}
#### Use Routes for Form Posts

Wheels's default wildcard `controller/action`-based URLs will not accept form posts for security reasons. This is due to an attack known as [Cross Site Request Forgery (CSRF)](https://owasp.org/www-community/attacks/csrf). We strongly recommend configuring [routes](https://wheels.dev/3.0.0/guides/handling-requests-with-controllers/routing) to post your forms to.
{% endhint %}

Most of the time, you'll probably be working with a resource. Your `/templates/base/src/config/routes.cfm` may look something like this:

{% code title="/templates/base/src/config/routes.cfm" %}
```javascript
mapper()
    .resources("users")
.end();
```
{% endcode %}

If you click the **Routes** link in the debug footer, you'll be most interested in these types of routes for your forms:

| Name  | Method | Pattern       | Controller | Action |
| ----- | ------ | ------------- | ---------- | ------ |
| users | GET    | /users        | users      | index  |
| users | POST   | /users        | users      | create |
| user  | PATCH  | /users/\[key] | users      | update |
| user  | DELETE | /users/\[key] | users      | delete |

Once you get to this list of routes, it really doesn't matter how you authored them in your `/templates/base/src/config/routes.cfm`. What matters is that you know the names, methods, and parameters that the routes expect. (With some practice, you'll probably be able to look at `/templates/base/src/config/routes.cfm` and know exactly what the names, methods, and parameters are though.)

If you are creating a record, your route is likely setup to accept a `POST` method. That happens to be the default for [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startFormTag.html), so you don't even need to include the `method` argument. You can then pass the `users` route name to the `route` argument:

{% code title="templates/base/src/app/views/users/new.cfm" %}
```html
<!--- `method` argument defaults to `post`, so we don't need to pass it in. --->
#startFormTag(route="users")#
#endFormTag()
```
{% endcode %}

If you need to send the form via another HTTP method, you can pass that in for the `method` argument as listed in your routes:

```html
<!---
    Search forms typically are done via `get` requests. This one is to
    the index. --->
#startFormTag(route="users", method="get")#
    #textFieldTag(type="search", name="q")#
    #submitTag("Search")#
#endFormTag()#

<!--- Update forms typically are sent via `patch` requests. --->
#startFormTag(route="user", key=user.key(), method="patch")#
    #textField(objectName="user", property="firstName")#
    #submitTag()#
#endFormTag()#

<!---
    Delete requests are best done via a form post, even if you're styling the
    form to look like a link.
--->
#startFormTag(
    route="user",
    key=user.key(),
    method="delete",
    class="inline-form"
)#
    #buttonTag(content="Delete User", class="link-button")#
#endFormTag()#
```

Notice above that the `user` route expects a `key` parameter, so that is passed into `startFormTag` as the `key`argument.

To drive the point home about routing parameters, let's say that we have this route:

| Name             | Method | Pattern                                              | Controller | Action |
| ---------------- | ------ | ---------------------------------------------------- | ---------- | ------ |
| productVariation | PATCH  | \[language]/products/\[productKey]/variations/\[key] | variations | update |

As you can see, the parameters can be anything, not just primary keys.

You would link up the form like so:

```html
#startFormTag(
    route="productVariation",
    language="es",
    productKey=product,key(),
    key=variation.key(),
    method="patch"
)#
    <!--- ... --->
#endFormTag()
```

### A Note About PATCH and DELETE Requests

Browsers (even the modern ones) tend to only work well with `GET` and `POST` requests, so how does Wheels also enable `PATCH` and `DELETE` requests?

To keep things secure, Wheels will still use `method="post"` on the form to send `PATCH` and `DELETE` requests. But the Wheels router will recognize a `PATCH` or `DELETE` request if a form variable called `_method` is also sent, specifying the `PATCH` or `DELETE` method.

Under the hood, [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startFormTag.html) will also generate a hidden field called `_method` that passes the request method along with the form `POST`.

So the `<form>` tag generated along with a `method` of `patch` will look something like this:

```html
<form action="/users/1234" method="post">
    <input type="hidden" name="_method" value="patch">
    <input type="hidden" name="authenticityToken" value="cxRbrHAnwpG0Ki9vTYW4yg==">
</form>
```

You'll notice that [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startFormTag.html) will also add another hidden field along with `POST`ed requests called `authenticityToken`, which helps prevent against [Cross-Site Request Forgery (CSRF) attacks](https://owasp.org/www-community/attacks/csrf).

The moral of the story: [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startFormTag.html) takes care of all of this for you. If you for some reason decide to wire up your own custom `<form>` tag that must `POST` data, be sure to add your own hidden fields for `_method` and use the [authenticityTokenField()](https://wheels.dev/api/v3.0.0/controller.authenticityTokenField.html) helper to generate the hidden field for the `authenticityToken` that Wheels will require on the `POST`.

### Refactoring Common Settings with Global Defaults

By setting up global defaults (as explained in the [Configuration and Defaults](https://wheels.dev/3.0.0/guides/working-with-wheels/configuration-and-defaults)) for the `prependToLabel`, `append`, and `labelPlacement` arguments, you can make the form code ever simpler across your whole application.

Here are the settings that you would apply in `/templates/base/src/config/settings.cfm`:

{% code title="/templates/base/src/config/settings.cfm" %}
```javascript
set(
    functionName="textField",
    prependToLabel="<div>",
    append="</div>",
    labelPlacement="before"
);

set(
    functionName="select",
    prependToLabel="<div>",
    append="</div>",
    labelPlacement="before"
);
```
{% endcode %}

And here's how our example code can be simplified as a result:

{% code title="templates/base/src/app/views/profiles/edit.cfm" %}
```html
<cfoutput>

#startFormTag(route="profile", method="patch")#
    #textField(label="First Name", objectName="profile", property="firstName")#
    #textField(label="Last Name", objectName="profile", property="lastName")#

    #select(
        label="Department",
        objectName="profile",
        property="departmentId",
        options=departments
    )#

    <div>
        #submitTag()#
    </div>
#endFormTag()#

</cfoutput>
```
{% endcode %}

All that the controller needs to provide at this point is a model object instance named `profile` that contains `firstName`, `lastName`, and `departmentId` properties and a query object named `departments` that contains identifier and text values. Note that the instance variable is named `profile`, though the model itself doesn't necessarily need to be named `profile`.

If you pass the form an empty instance named `profile` (for example, created by [new()](https://wheels.dev/api/v3.0.0/model.new.html), the form will display blank values for all the fields. If you pass it an object created by a finder like [findOne()](https://wheels.dev/api/v3.0.0/model.findone.html) or [findByKey()](https://wheels.dev/api/v3.0.0/model.findbykey.html), then the form will display the values provided through the object. This allows for us to potentially use the same view file for both create and update scenarios in our application.

### Refactoring Label Names

If you look at the previous examples, there is one other bit of configuration that we can clean up: the `label` arguments passed to [textField()](https://wheels.dev/api/v3.0.0/controller.textField.html) and [select()](https://wheels.dev/api/v3.0.0/controller.select.html).

Because we've named `firstName`, `lastName`, and `departmentId` in conventional ways (camel case), Wheels will generate the labels for us automatically:

{% code title="templates/base/src/app/views/profiles/edit.cfm" %}
```html
<cfoutput>

#startFormTag(route="profile", method="patch")#
    #textField(objectName="profile", property="firstName")#
    #textField(objectName="profile", property="lastName")#

    #select(
        objectName="profile",
        property="departmentId",
        options=departments
    )#

    <div>
        #submitTag()#
    </div>
#endFormTag()#

</cfoutput>
```
{% endcode %}

You'll notice that Wheels is even smart enough to translate the `departmentId` property to `Department`.

If you ever need to override a label, you can do so in the model's initializer using the `label` argument of the [property()](https://wheels.dev/api/v3.0.0/model.property.html)method:

{% code title="templates/base/src/app/models/User.cfc" %}
```javascript
component extends="Model" {
    function init() {
        property(name="lastName", label="Surname");
    }
}
```
{% endcode %}

### Form Error Messages

If you really want to secure a form, you need to do it server side. Sure, you can add JavaScript here and there to validate your web form. Unfortunately, disabling JavaScript (and thus your JavaScript-powered form validation) is simple in web browsers, and malicious bots tend not to listen to JavaScript.

Securing the integrity of your web forms in Wheels on the server side is very easy. Assuming that you have read the chapter on [Object Validation](https://wheels.dev/3.0.0/guides/database-interaction-through-models/object-validation), you can rest assured that your code is a lot more secure now.

### Displaying a List of Model Validation Errors

Wheels provides you with a tool set of Helper Functions just for displaying error messages as well.

In the controller, let's say that this just happened. Your model includes validations that require the presence of both `firstName` and `lastName`. The user didn't enter either. So in the controller's `update` action, it loads the model object, sets the values that the user submitted, sees that there was a validation error after calling [update()](https://wheels.dev/api/v3.0.0/model.update.html), and displays the form view again.

The `update` action may look something like this:

{% code title="templates/base/src/app/controllers/Profiles.cfc" %}
```javascript
function update() {
    // In this example, we're loading an existing object based on the user's
    // session.
    profile = model("user").findByKey(session.userId);

    // If everything validated, then send user to success message
    if (profile.update(params.profile)) {
        flashInsert(success="Profile updated.");
    }
    // If there were errors with the form submission, show the form again
    // with errors.
    else {
        flashInsert(error="There was an error with your changes.");
        renderView(action="edit");
    }
}
```
{% endcode %}

Notice that the view for the `edit` action is rendered if the `profile` object's [update()](https://wheels.dev/api/v3.0.0/model.update.html) returns `false`.

Let's take the previous form example and add some visual indication to the user about what he did wrong and where, by simply adding the following code on your form page.

{% code title="templates/base/src/app/views/profiles/edit.cfm" %}
```html
<cfoutput>

#errorMessagesFor("profile")#

#startFormTag(route="profile", method="patch")#
    #textField(objectName="profile", property="firstName")#
    #textField(objectName="profile", property="lastName")#

    #select(
        objectName="department",
        property="departmentId",
        options=departments
    )#

    <div>
        #submitTag()#
    </div>
#endFormTag()#

</cfoutput>
```
{% endcode %}

How about that? With just that line of code (and the required validations on your object model), Wheels will do the following:

* Generate an HTML unordered list with a HTML class name of `errorMessages`.
* Display all the error messages on your `profile` object as list items in that unordered list.
* Wrap each of the erroneous fields in your form with a surrounding `<div class="fieldWithErrors">` HTML tag for you to enrich with your ninja CSS skills.

There is no longer the need to manually code error logic in your form markup.

### Showing Individual Fields' Error Messages

Let's say that would rather display the error messages just below the failed fields (or anywhere else, for that matter). Wheels has that covered too. All that it takes is a simple line of code for each form field that could end up displaying feedback to the user.

Let's add some error message handlers for the `firstName`, `lastName`, and `departmentId` fields:

{% code title="templates/base/src/app/views/profiles/edit.cfm" %}
```html
<cfoutput>

#startFormTag(route="profile", method="patch")#
    #textField(objectName="profile", property="firstName")#
    #errorMessageOn(objectName="profile", property="firstName")#

    #textField(objectName="profile", property="lastName")#
    #errorMessageOn(objectName="profile", property="lastName")#

    #selectTag(
        objectName="profile",
        property="departmentId",
        options=departments
    )#
    #errorMessageOn(objectName="profile", property="departmentId")#

    <div>
        #submitTag()#
    </div>
#endFormTag()#

</cfoutput>
```
{% endcode %}

Notice the call to the [errorMessageOn()](https://wheels.dev/api/v3.0.0/controller.errormessageon.html) function below the `firstName`, `lastName`, and `departmentId` fields. That's all it takes to display the corresponding error messages of each form control on your form.

And the error messages won't even display if there aren't any. That way you can yet again use the same form code for error and non-error scenarios alike.

### Types of Form Helpers

There is a Wheels form helper for basically every type of form element available in HTML. And they all have the ability to be bound to Wheels model instances to make displaying values and errors easier. Here is a brief description of each helper.

### Text, Password, and TextArea Fields

Text and password fields work similarly to each other. They allow you to show labels and bind to model object instances to determine whether or not a value should be pre-populated.

```html
#textField(objectName="user", property="username")#
#passwordField(objectName="user", property="password")#
#textArea(objectName="user", property="biography", rows=5, cols=40)#
```

May yield the equivalent to this HTML (if we assume the global defaults defined above in the section named _Factoring out Common Settings with Global Defaults_):

```html
<div>
    <label for="user-username">Username</label>
    <input id="user-username" type="text" name="user[username]" value="cfguy">
</div>
<div>
    <label for="user-password">Password</label>
    <input id="user-password" type="password" name="user[password]" value="">
</div>
<div>
    <label for="user-biography">Bio</label>
    <textarea id="user-biography" name="user[biography]">
        CF Guy really is a great guy. He's much nicer than .NET guy.
    </textarea>
</div>
```

### Hidden Fields

Hidden fields are powered by the [hiddenField()](https://wheels.dev/api/v3.0.0/controller.hiddenfield.html) form helper, and it also works similarly to [textField()](https://wheels.dev/api/v3.0.0/controller.textfield.html) and [passwordField()](https://wheels.dev/api/v3.0.0/controller.passwordfield.html).

```html
#hiddenField(objectName="user", property="referralSourceId")#
```

Would yield this type of markup:

```html
<input type="hidden" name="user[referralSourceId]" value="425">
```

### Select Fields

As hinted in our first example of form helpers, the [select()](https://wheels.dev/api/v3.0.0/controller.select.html) function builds a `<select>` list with options. What's really cool about this helper is that it can populate the `<option>`s with values from a query, struct, or array.

Take a look at this line:

```html
#select(objectName="user", property="departmentId", options=departments)#
```

Assume that the `departments` variable passed to the options argument contains a query, struct, or array of department data that should be selectable in the drop-down.

Each data type has its advantages and disadvantages:

* **Queries** allow you to order your results, but you can only use one column. But this can be overcome using [Calculated Properties](https://wheels.dev/3.0.0/guides/database-interaction-through-models/calculated-properties).
* **Structs** allow you to build out static or dynamic values using whatever data that you please, but there is no guarantee that your CFML engine will honor the order in which you add the elements.
* **Arrays** also allow you to build out static or dynamic values, and there is a guarantee that your CFML engine will honor the order. But arrays are a tad more verbose to work with.

Wheels will examine the data passed to `options` and intelligently pick out elements to populate for the `<option>`s' values and text.

* **Query**: Wheels will try to pick out the first numeric column for `value` and the first non-numeric column for the display text. The order of the columns is determined how you have them defined in your database.
* **Struct**: Wheels will use the keys as the `value` and the values as the display text.
* **Array**: Wheels will react depending on how many dimensions there are. If it's only a single dimension, it will populate both the `value` and display text with the elements. When it's a 2D array, Wheels will use each item's first element as the `value` and each element's second element as the display text. For anything larger than 2 dimensions, Wheels only uses the first 2 sub-elements and ignores the rest.

Here's an example of how you might use each option:

```javascript
// Query generated in your controller --->
departments = findAll(orderBy="name");

// Hard-coded struct set up in templates/base/src/app/events/onapplicationstart.cfm
application.departments["1"] = "Sales";
application.departments["2"] = "Marketing";
application.departments["3"] = "Information Technology";
application.departments["4"] = "Human Resources";

// Array built from query call in model
departments = this.findAll(orderBy="lastName,hq");

departmentsArray = [];

for (department in departments) {
    ArrayAppend(
        departmentsArray,
        [department.id, "#department.name# - #department.hq#"]
    );
}
```

When sending a query, if you need to populate your `<option>`s' values and display text with specific columns, you should pass the names of the columns to use as the `textField` and `valueField` arguments.

You can also include a blank option by passing true or the desired text to the `includeBlank` argument.

Here's a full usage with this new knowledge:

```html
#select(
    objectName="user",
    property="departmentId",
    options=departments,
    valueField="id",
    textField="departmentName",
    includeBlank="Select a Department"
)#
```

#### Multiple Select Fields

The [select()](https://wheels.dev/api/v3.0.0/controller.select.html) function also supports multiple selections by passing `multiple=true`. This creates a multi-select box that allows users to select more than one option:

```html
#select(
    objectName="user",
    property="roleIds",
    options=roles,
    valueField="id",
    textField="roleName",
    multiple=true
)#
```

When using `multiple=true`, the property should be able to handle multiple values (typically an array or a list). The rendered HTML will include the `multiple="multiple"` attribute on the `<select>` element, allowing users to select multiple options by holding down Ctrl (Windows/Linux) or Cmd (Mac) while clicking.

### Radio Buttons

Radio buttons via [radioButton()](https://wheels.dev/api/v3.0.0/controller.radiobutton.html) also take `objectName` and `property` values, and they accept an argument called `tagValue` that determines what value should be passed based on what the user selects.

Here is an example using a query object called `eyeColor` to power the possible values:

```html
<fieldset>
    <legend>Eye Color</legend>

    <cfloop query="eyeColor">
        #radioButton(
            label=eyeColor.color,
            objectName="profile",
            property="eyeColorId",
            tagValue=eyeColor.id,
            labelPlacement="after"
        )#<br>
    </cfloop>
</fieldset>
```

If the `profile` object already has a value set for `eyeColorId`, then [radioButton()](https://wheels.dev/api/v3.0.0/controller.radiobutton.html) will make sure that that value is checked on page load.

If `profile.eyeColorId`'s value were already set to `1`, the rendered HTML would appear similar to this:

```html
<fieldset>
    <legend>Eye Color</legend>

    <input
        type="radio"
        id="profile-eyeColorId-2"
        name="profile[eyeColorId]"
        value="2"
    >
    <label for="profile-eyeColorId-2">Blue</label><br>

    <input
        type="radio"
        id="profile-eyeColorId-1"
        name="profile[eyeColorId]"
        value="1"
        checked="checked"
    >
    <label for="profile-eyeColorId-1">Brown</label><br>

    <input
        type="radio"
        id="profile-eyeColorId-3"
        name="profile[eyeColorId]"
        value="3"
    >
    <label for="profile-eyeColorId-3">Hazel</label><br>
</fieldset>
```

Note that if you don't specify `labelPlacement="after"` in your calls to [radioButton()](https://wheels.dev/api/v3.0.0/controller.radiobutton.html), Wheels will place the labels before the form controls.

### Check Boxes

Check boxes work similarly to radio buttons, except [checkBox()](https://wheels.dev/api/v3.0.0/controller.checkbox.html) takes parameters called `checkedValue` and `uncheckedValue` to determine whether or not the check box should be checked on load.

Note that binding check boxes to model objects is best suited for properties in your object that have a `yes/no` or `true/false` type value.

```html
#checkBox(
    label="Sign me up for the email newsletter.",
    objectName="customer",
    property="newsletterSubscription",
    labelPlacement="after"
)#
```

Because the concept of check boxes don't tie too well to models (you can select several for the same "property"), we recommend using [checkBoxTag()](https://wheels.dev/api/v3.0.0/controller.checkboxtag.html) instead if you want to use check boxes for more values than just true/false. See the _Helpers That Aren't Bound to Model Objects_ section below.

### File Fields

The [fileField()](https://wheels.dev/api/v3.0.0/controller.filefield.html) helper builds a file field form control based on the supplied `objectName` and `property`.

```html
#fileField(label="Photo", objectName="profile", property="photo")#
```

In order for your form to pass the correct `enctype`, you can pass `multipart=true` to [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startformtag.html):

```html
#startFormTag(route="attachments", multipart=true)#
```

### Setting a Default Value on an Object-bound Field

Looking at this form code, it isn't 100% evident how to set an initial value for the fields:

{% code title="templates/base/src/app/views/accounts/new.cfm" %}
```html
#startFormTag(route="accounts")#
    #textField(objectName="account", property="title")#
    #select(objectName="account", property="accountTypeId")#
    #checkBox(objectName="account", property="subscribedToNewsletter")#
#endFormTag()#
```
{% endcode %}

What if we want a random title pre-filled, a certain account type pre-selected, and the check box automatically checked when the form first loads?

The answer lies in the `account` object that the fields are bound to. Let's say that you always wanted this behavior to happen when the form for a new account loads. You can do something like this in the controller:

{% code title="templates/base/src/app/controllers/Accounts.cfc" %}
```javascript
component extends="controllers.Controller" {
    function new() {
        local.defaultAccountType = model("accountType").findOne(
          where="isDefault=1"
        );

        account = model("account").new(
            title=generateRandomTitle(),
            accountTypeId=local.defaultAccountType.key(),
            subscribedToNewsletter=true
        );
    }
}
```
{% endcode %}

Now the initial state of the form will reflect the default values setup on the object in the controller.

### Helpers That Aren't Bound to Model Objects

Sometimes you'll want to output a form element that isn't bound to a model object.

A search form that passes the user's query as a variable in the URL called `q` is a good example. In this example case, you would use the [textFieldTag()](https://wheels.dev/api/v3.0.0/controller.textfieldtag.html) function to produce the `<input>` tag needed.

```html
#textFieldTag(label="Search", name="q", value=params.q)#
```

There are "tag" versions of all of the form helpers that we've listed in this chapter. As a rule of thumb, add `Tag` to the end of the function name and use the `name` and `value`, `checked`, and `selected` arguments instead of the `objectName` and `property` arguments that you normally use.

Here is a list of the "tag" helpers for your reference:

* [checkBoxTag()](https://wheels.dev/api/v3.0.0/controller.checkboxtag.html)
* [hiddenFieldTag()](https://wheels.dev/api/v3.0.0/controller.hiddenfieldtag.html)
* [passwordFieldTag()](https://wheels.dev/api/v3.0.0/controller.passwordfieldtag.html)
* [radioButtonTag()](https://wheels.dev/api/v3.0.0/controller.radiobuttontag.html)
* [selectTag()](https://wheels.dev/api/v3.0.0/controller.selecttag.html)
* [textAreaTag()](https://wheels.dev/api/v3.0.0/controller.textareatag.html)
* [textFieldTag()](https://wheels.dev/api/v3.0.0/controller.textfieldtag.html)

### Passing Extra Arguments for HTML Attributes

Much like Wheels's [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) function, any extra arguments that you pass to form helpers will be passed to the corresponding HTML tag as attributes.

For example, if we wanted to define a `class` on our starting form tag, we just pass that as an extra argument to [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startformtag.html):

```html
#startFormTag(route="posts", class="login-form")#
```

Which would produce this HTML:

```html
<form action="/posts" method="post" class="login-form">
```

When a form helper creates more than one HTML element you can typically pass in extra arguments to be set on that element as well. One common example of this is when you need to set a `class` for a `label` element; you can do so by passing in `labelClass="class-name"`. Wheels will detect that your argument starts with "label" and assume it should go on the `label` element and not the `input` element (or whatever "main" element the form helper creates). This means you could also pass in `labelId="my-id"` to set the `id` on the `label` for example.

### Boolean Attributes

HTML includes many boolean attributes like `novalidate`, `disabled`, `required`, etc.

If you want for a Wheels view helper to render one of these attributes, just pass the name of the attribute as an extra argument, set it to `true`, and Wheels will include the boolean attribute:

```html
#textField(objectName="post", property="title", required=true)#
-> <input type="text" name="post[title]" value="" required>
```

### HTML5 data Attributes

`data` attributes in HTML usually look something like this:

```html
<input type="submit" value="Submit" data-ajax-url="/contacts/send.js">
```

Because ColdFusion arguments cannot contain any hyphens, we have constructed a workaround for you for Wheels view helpers.

Let's say you want a `data-ajax-url` HTML attribute as depicted above. All you need to do is pass in an argument named `dataAjaxUrl`, and Wheels will convert that attribute name to the hyphenated version in the HTML output.

```html
#submitTag(
    value="Submit",
    dataAjaxUrl=urlFor(route="contactsSend", format="js")
)#
-> <input type="submit" value="Submit" data-ajax-url="/contacts/send.js">
```

As an alternative, you can pass in `data_ajax_url` instead if you prefer underscores, and it will produce the same result.

### Special Form Helpers

Wheels provides a few extra form helpers that make it easier for you to generate accessible fields for dates and/or times. These also bind to properties that are of type `DATE, TIMESTAMP, DATETIME`, etc.

We won't go over these in detail, but here is a list of the date and time form helpers available:

* [dateSelect()](https://wheels.dev/api/v3.0.0/controller.dateselect.html)
* [dateSelectTags()](https://wheels.dev/api/v3.0.0/controller.dateselecttags.html)
* [timeSelect()](https://wheels.dev/api/v3.0.0/controller.timeselect.html)
* [timeSelectTags()](https://wheels.dev/api/v3.0.0/controller.timeselecttags.html)
* [dateTimeSelect()](https://wheels.dev/api/v3.0.0/controller.datetimeselect.html)
* [dateTimeSelectTags()](https://wheels.dev/api/v3.0.0/controller.datetimeselecttags.html)
* [yearSelectTag()](https://wheels.dev/api/v3.0.0/controller.yearselecttag.html)
* [monthSelectTag()](https://wheels.dev/api/v3.0.0/controller.monthselecttag.html)
* [daySelectTag()](https://wheels.dev/api/v3.0.0/controller.dayselecttag.html)
* [hourSelectTag()](https://wheels.dev/api/v3.0.0/controller.hourselecttag.html)
* [minuteSelectTag()](https://wheels.dev/api/v3.0.0/controller.minuteselecttag.html)
* [secondSelectTag()](https://wheels.dev/api/v3.0.0/controller.secondselecttag.html)
