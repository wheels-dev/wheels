---
description: >-
  The routing system in Wheels encourages a conventional RESTful and
  resourceful style of request handling.
---

# Routing

The Wheels routing system inspects a request's HTTP verb and URL and decides which controller and action to run.

Consider the following request:

{% code title="HTTP" %}
```http
GET /products/5
```
{% endcode %}

The routing system may match the request to a route like this, which tells Wheels to load the `show` action on the `Products` controller:

```javascript
.get(name="product", pattern="products/[key]", to="products##show")
```

### Configuring Routes

To configure routes, open the file at `app/config/routes.cfm`.

The Wheels router begins with a call to [mapper()](https://wheels.dev/api/v3.0.0/controller.mapper.html), various methods chained from that, and lastly ends with a call to `end()`.

In many cases, if you need to know where to go in the code to work with existing functionality in an application, the `routes.cfm` file can be a handy map, telling you which controller and action to start looking in.

### How Routes Work

The various route mapping methods that we'll introduce in this chapter basically set up a list of routes, matching URL paths to a controllers and actions within your application.

The terminology goes like this:

#### Name

A route _name_ is set up for reference in your CFML code for building [links](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/displaying-views-to-users/linking-pages), [forms](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/displaying-views-to-users/form-helpers-and-showing-errors), and such. To build URLs, you'll use this name along with helpers like [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html), [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startformtag.html), [urlFor()](https://wheels.dev/api/v3.0.0/controller.urlfor.html), and so on.

#### Method

A HTTP request _method_ must be defined: `GET`, `POST`, `PATCH`, or `DELETE`.

You typically want to require `POST`, `PATCH`, or `DELETE` when a given action changes the state of your application's data:

* Creating record(s): `POST`
* Updating record(s): `PATCH`
* Deleting record(s): `DELETE`

You can permit listing and showing records behind a normal HTTP `GET` request method.

#### Pattern and Parameters

A _pattern_ is a URL path, sometimes with _parameters_ in `[squareBrackets]`. Parameter values get sent to the controller in the `params` struct.

You'll see patterns like these in routes:

{% code title="Example Route Patterns" %}
```
posts/[key]/[slug]
posts/[key]
posts
```
{% endcode %}

In this example, `key` and `slug` are parameters that must be present in the URL for the first route to match, and they are required when linking to the route. In the controller, these parameters will be available at `params.key` and `params.slug`, respectively.&#x20;

When a request is made to Wheels, the router will look for the first route that matches the requested URL. As an example, this means that if `key` is present in the URL but not `slug`, then it's the second route above that will match.

{% hint style="warning" %}
Please note that `.` is treated as a special characters in patterns and should generally not be used (one exception being when you are [responding with multiple formats](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/responding-with-multiple-formats)). If your parameters may have `.` in their value, please use the long form URL format: `/?controller=[controller_name]&action=[action_name]&[parameter_name]=[parameter_value]`
{% endhint %}

### Viewing a List of Routes

In the debugging footer, you'll see a **Routes** link:

> \[info, **View Routes**, Docs, Tests, Migrator, Plugins]

Clicking that will load a filterable list of routes drawn in the `app/config/routes.cfm` file, including name, method, pattern, controller, and action.

If you don't see debugging information at the bottom of the page, see the docs for the `showDebugInformation` setting in the [Configuration and Defaults](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/working-with-wheels/configuration-and-defaults) chapter.

### Resource Routing

Many parts of your application will likely be CRUD-based (create, read, update, delete) for specific types of records (users, products, categories). _Resources_ allow you to define a conventional routing structure for this common use case.

{% hint style="warning" %}
#### Resources are important

You'll want to pay close attention to how resource-based routing works because this is considered an important convention in Wheels applications.
{% endhint %}

If we have a `products` table and want to have a section of our application for managing the products, we can set up the routes using the [resources()](https://wheels.dev/api/v3.0.0/mapper.resources.html) method like this in `app/config/routes.cfm`:

{% code title="/app/config/routes.cfm" %}
```javascript
mapper()
    .resources("products")
.end();
```
{% endcode %}

This will set up the following routes, pointing to specific actions within the `products` controller:

| Name        | HTTP Verb | Path                  | Controller & Action | Description                                    |
| ----------- | --------- | --------------------- | ------------------- | ---------------------------------------------- |
| products    | GET       | /products             | products.index      | Display a list of all products                 |
| product     | GET       | /products/\[key]      | products.show       | Display a specific product                     |
| newProduct  | GET       | /products/new         | products.new        | Display a form for creating a new product      |
| products    | POST      | /products             | products.create     | Create a new product record                    |
| editProduct | GET       | /products/\[key]/edit | products.edit       | Display a form for editing an existing product |
| product     | PATCH/PUT | /products/\[key]      | products.update     | Update an existing product record              |
| product     | DELETE    | /products/\[key]      | products.delete     | Delete an existing product record              |

Because the router uses a combination of HTTP verb and path, we only need 4 different URL paths to connect to 7 different actions on the controller.

{% hint style="info" %}
#### What's with the `PUT`?

There has been some confusion in the web community on whether requests to update data should happen along with a `PUT` or `PATCH` HTTP verb. It has been settled mostly that `PATCH` is the way to go for most situations. Wheels resources set up both `PUT` and `PATCH` to address this confusion, but you should probably prefer linking up `PATCH` when you are able.
{% endhint %}

### Singular Resources

Standard resources using the [resources()](https://wheels.dev/api/v3.0.0/mapper.resources.html) method assume that there is a primary key associated with the resource. (Notice the `[key]` placeholder in the paths listed above in the _Strongly Encouraged: Resource Routing_ section.)

Wheels also provides a _singular_ resource for routing that will not expose a primary key through the URL.

```javascript
mapper()
    .resource("cart")
.end();
```

This is handy especially when you're manipulating records related directly to the user's session (e.g., a profile or a cart can be managed by the user without exposing the primary key of the underlying database records).

Calling [resource()](https://wheels.dev/api/v3.0.0/mapper.resource.html) (notice that there's no "s" on the end) then exposes the following routes:

| Name     | HTTP Verb | Path       | Controller & Action | Description                            |
| -------- | --------- | ---------- | ------------------- | -------------------------------------- |
| cart     | GET       | /cart      | carts.show          | Display the cart                       |
| newCart  | GET       | /cart/new  | carts.new           | Display a form for creating a new cart |
| cart     | POST      | /cart      | carts.create        | Create a new cart record               |
| editCart | GET       | /cart/edit | carts.edit          | Display a form for editing the cart    |
| cart     | PATCH/PUT | /cart      | carts.update        | Update the cart record                 |
| cart     | DELETE    | /cart      | carts.delete        | Delete the cart                        |

Note that even though the resource path is singular, the name of the controller is plural by convention.

Also, this example is slightly contrived because it doesn't make much sense to create a "new" cart as a user typically just has one and only one cart tied to their session.

### Defining Individual URL Endpoints

As you've seen, defining a resource creates several routes for you automatically, and it is great for setting up groupings of routes for managing resources within your application.

But sometimes you just need to define a single one-off route pattern. For this case, you have a method for each HTTP verb: [get()](https://wheels.dev/api/v3.0.0/mapper.get.html), [post()](https://wheels.dev/api/v3.0.0/mapper.post.html), [patch()](https://wheels.dev/api/v3.0.0/mapper.patch.html), [put()](https://wheels.dev/api/v3.0.0/mapper.put.html), and [delete()](https://wheels.dev/api/v3.0.0/mapper.delete.html).

As a refresher, these are the intended purpose for each HTTP verb:

| HTTP Verb | Meaning                           |
| --------- | --------------------------------- |
| GET       | Display a list or record          |
| POST      | Create a record                   |
| PATCH/PUT | Update a record or set of records |
| DELETE    | Delete a record                   |

{% hint style="danger" %}
#### Security Warning

We strongly recommend that you not allow any `GET` requests to modify resources in your database (i.e., creating, updating, or deleting records). Always require `POST`, `PUT`, `PATCH`, or `DELETE` verbs for those sorts of routing endpoints.
{% endhint %}

Consider a few examples:

{% code title="app/config/routes.cfm" %}
```javascript
mapper()
    .patch(name="heartbeat", to="sessions##update")

    .patch(
        name="usersActivate",
        pattern="users/[userKey]/activations",
        to="activations##update"
    )

    .resources("users")

    .get(name="privacy", controller="pages", action="privacy")
    .get(name="dashboard", controller="dashboards", action="show")
.end();
```
{% endcode %}

Rather than creating a whole resource for simple one-off actions or pages, you can create individual endpoints for them.

Notice that you can use the `to="controller##action"` or use separate `controller`/`action` arguments. The `to`argument allows you to delineate `controller` and `action` within a single string using a `#` separator (which must be escaped as a double `##` because of CFML's special usage of that symbol within string syntax).

In fact, you could mock a `users` resource using these methods like so (though obviously there is little practical reason for doing so):

{% code title="app/config/routes.cfm" %}
```javascript
mapper()
    // The following is roughly equivalent to .resources("users")
    .get(name="newUser", pattern="users/new", to="users##new")
    .get(name="editUser", pattern="users/[key]/edit", to="users##edit")
    .get(name="user", pattern="users/[key]", to="users##show")
    .patch(name="user", pattern="users/[key]", to="users##update")
    .put(name="user", pattern="users/[key]", to="users##update")
    .delete(name="user", pattern="users/[key]", to="users##delete")
    .post(name="users", to="users##create")
    .get(name="users", to="users##index")
.end();
```
{% endcode %}

If you need to limit the actions that are exposed by [resources()](https://wheels.dev/api/v3.0.0/mapper.resources.html) and [resource()](https://wheels.dev/api/v3.0.0/mapper.resource.html), you can also pass in `only` or `except`arguments:

{% code title="app/config/routes.cfm" %}
```javascript
mapper()
    // Only offer endpoints for cart show, update, and delete:
    // -  GET /cart
    // -  PATCH /cart
    // -  DELETE /cart
    .resource(name="cart", only="show,update,delete")

    // Offer all endpoints for wishlists, except for delete:
    // -  GET /wishlists
    // -  GET /wishlists/new
    // -  GET /wishlists/[key]
    // -  GET /wishlists/[key]/edit
    // -  POST /wishlists
    // -  PATCH /wishlists/[key]
    .resources(name="wishlists", except="delete")
.end();
```
{% endcode %}

### Browser Support for PUT, PATCH, and DELETE

While web standards advocate for usage of these specific HTTP verbs for requests, web browsers don't do a particularly good job of supporting verbs other than `GET` or `POST`.

To get around this, the Wheels router recognizes the specialized verbs from browsers (`PUT`, `PATCH`, and `DELETE`) in this way:

* Via a `POST` request with a
* `POST` variable named `_method` specifying the specific HTTP verb (e.g., `_method=delete`)

See the chapter on [Linking Pages](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/displaying-views-to-users/linking-pages) for strategies for working with this constraint.

Note that using Wheels to write a REST API doesn't typically have this constraint. You should confidently require API clients to use the specific verbs like `PATCH` and `DELETE`.

### Namespaces

The Wheels router allows for _namespaces_: the ability to add a route to a "subfolder" in the URL as well as within the `controllers` folder of your application.

Let's say that we want to have an "admin" section of the application that is separate from other "public" sections. We'd want for all of the "admin" controllers to be within an admin subfolder both in the URL and our application.

That's what the [namespace()](https://wheels.dev/api/v3.0.0/mapper.namespace.html) method is for:

```javascript
mapper()
    .namespace("admin")
        .resources("products")
    .end()
.end();
```

In this example, we have an admin section that will allow the user to manage products. The URL would expose the products section at `/admin/products`, and the controller would be stored at `app/controllers/admin/Products.cfc`.

### Packages

Let's say that you want to group a set of controllers together in a subfolder (aka package) in your application but don't want to affect a URL. You can do so using the `package` mapper method:&#x20;

```javascript
mapper()
    .package("public")
        .resources("articles")
        .resource("profile")
    .end()
.end();
```

With this setup, end users will see `/articles` and `/profile` in the URL, but the controllers will be located at `app/controllers/public/Articles.cfc` and `controllers/public/Profiles.cfc`, respectively.

### Nested Resources

You'll often find yourself implementing a UI where you need to manipulate data scoped to a parent record. Creating nested resources allows you to reflect this nesting relationship in the URL.

Let's consider an example where we want to enable CRUD for a `customer` and its children `appointment` records.

In this situation, we'd perhaps want for our URL to look like this for editing a specific customer's appointment:

{% code title="HTTP" %}
```
GET /customers/489/appointments/1909/edit
```
{% endcode %}

To code up this nested resource, we'd write this code in `app/config/routes.cfm`:

```javascript
mapper()
    .resources(name="customers", nested=true)
        .resources("appointments")
    .end()
.end();
```

That will create the following routes:

|                         | HTTP Verb | Path                                               | Controller & Action | Description                                                                |
| ----------------------- | --------- | -------------------------------------------------- | ------------------- | -------------------------------------------------------------------------- |
| newCustomerAppointment  | GET       | /customers/\[customerKey]/appointments/new         | appointments.new    | Display a form for creating a new appointment for a specific customer      |
| customerAppointment     | GET       | /customers/\[customerKey]/appointments/\[key]      | appointments.show   | Display an existing appointment for a specific customer                    |
| editCustomerAppointment | GET       | /customers/\[customerKey]/appointments/\[key]/edit | appointments.edit   | Display a form for editing an existing appointment for a specific customer |
| customerAppointment     | PATCH/PUT | /customers/\[customerKey]/appointments/\[key]      | appointments.update | Update an existing appointment record for a specific customer              |
| customerAppointment     | DELETE    | /customers/\[customerKey]/appointments/\[key]      | appointments.delete | Delete an existing appointment record for an specific customer             |
| customerAppointments    | GET       | /customers/\[customerKey]/appointments             | appointments.index  | List appointments for a specific customer                                  |
| customerAppointments    | POST      | /customers/\[customerKey]/appointments             | appointments.create | Create an appointment record for a specific customer                       |
| newCustomer             | GET       | /customers/new                                     | customers.new       | Display a form for creating a customer                                     |
| customer                | GET       | /customers/\[key]                                  | customers.show      | Display an existing customer                                               |
| editCustomer            | GET       | /customers/\[key]/edit                             | customers.edit      | Display a form for editing an existing customer                            |
| customer                | PATCH/PUT | /customers/\[key]                                  | customers.update    | Update an existing customer                                                |
| customer                | DELETE    | /customers/\[key]                                  | customers.delete    | Delete an existing customer                                                |
| customers               | GET       | /customers                                         | customers.index     | Display a list of all customers                                            |
| customers               | POST      | /customers                                         | customers.create    | Create a customer                                                          |

Notice that the routes for the `appointments` resource contain a parameter named `customerKey`. The parent resource's ID will always be represented by its name appended with `Key`. The child will retain the standard `key` ID.

You can nest resources and routes as deep as you want, though we recommend considering making the nesting shallower after you get to a few levels deep.

Here's an example of how nesting can be used with different route mapping methods:

```javascript
mapper()
    // /products/[key]
    .resources(name="products", nested=true)
        // /products/[productKey]/promote
        .patch(name="promote", to="promotions##create")
        // /products/[productKey]/expire
        .delete(name="expire", to="expirations##create")

        // A 2nd-level resource
        // /products/[productKey]/variations/[key]
        .resources(name="variations", nested=true)
            // A 3rd-level resource
            // /products/[productKey]/variations/[variationKey]/primary
            .resource("primary")
        .end()
    .end()
.end();
```

### Wildcard Routes

Wheels 1.x had a default routing pattern: `[controller]/[action]/[key]`. The convention for URLs was as follows:

{% code title="HTTP" %}
```http
GET /news/show/5
```
{% endcode %}

With this convention, the URL above told Wheels to invoke the `show` action in the `news` controller. It also passed a parameter called `key` to the action, with a value of `5`.

If you're upgrading from 1.x or still prefer this style of routing for your Wheels 2+ application, you can use the [wildcard()](https://wheels.dev/api/v3.0.0/mapper.wildcard.html) method to enable it part of it:&#x20;

```javascript
mapper()
    .wildcard()
.end();
```

Wheels 2 will only generate routes for `[controller]/[action]`, however, because resources and the other routing methods are more appropriate for working with records identified by primary keys.

Here is a sample of the patterns that `wildcard` generates:

```
/news/new
/news/create
/news/index
/news
```

The `wildcard` method by default will only generate routes for the `GET` request method. If you would like to enable other request methods on the wildcard, you can pass in the `method` or `methods` argument:

```javascript
mapper()
    .wildcard(methods="get,post")
.end();
```

{% hint style="danger" %}
#### Security Warning

Specifying a `method` argument to `wildcard` with anything other than `get` gives you the potential to accidentally expose a route that could change data in your application with a `GET` request. This opens your application to Cross Site Request Forgery (CSRF) vulnerabilities.

`wildcard` is provided for convenience. Once you're comfortable with routing concepts in Wheels, we strongly recommend that you use resources (`resources`, `resource`) and the other verb-based helpers (`get`, `post`, `patch`, `put`, and `delete`) listed above instead.
{% endhint %}

### Order of Precedence

Wheels gives precedence to the first listed custom route in your `app/config/routes.cfm` file.

Consider this example to demonstrate when this can create unexpected issues:

```javascript
mapper()
    .resources("users")

    .get(
        name="usersPromoted",
        pattern="users/promoted",
        to="userPromotions##index"
    )
.end();
```

In this case, when the user visits `/users/promoted`, this will load the `show` action of the `users` controller because that was the first pattern that was matched by the Wheels router.

To fix this, you need the more specific route listed first, leaving the dynamic routing to pick up the less specific pattern:

```javascript
mapper()
    .get(
        name="usersPromoted",
        pattern="users/promoted",
        to="userPromotions##index"
    )

    .resources("users")
.end();
```

### Making a Catch-All Route

Sometimes you need a catch-all route in Wheels to support highly dynamic websites (like a content management system, for example), where all requests that are not matched by an existing route get passed to a controller/action that can deal with it.

Let's say you want to have both `/welcome-to-the-site` and `/terms-of-use` handled by the same controller and action. Here's what you can do to achieve this.

First, add a new route to `app/config/routes.cfm` that catches all pages like this:

```javascript
mapper()
    .get(name="page", pattern="[title]", to="pages##show")
.end();
```

Now when you access `/welcome-to-the-site`, this route will be triggered and the `show` action will be called on the `pages` controller with `params.title` set to `welcome-to-the-site`.

The problem with this is that this will break any of your normal controllers though, so you'll need to add them specifically _before_ this route. (Remember the order of precedence explained above.)

You'll end up with a `app/config/routes.cfm` file looking something like this:

```javascript
mapper()
    .resources("products")
    .get(name="logout", to="sessions#delete")
    .get(name="page", pattern="[title]", to="pages##show")
    .root(to="dashboards##show")
.end();
```

`products` and `sessions` are your normal controllers. By adding them to the top of the routes file, Wheels looks for them first. But your catch-all route is more specific than the site root (`/`), so your catch-all should be listed before the call to [root()](https://wheels.dev/api/v3.0.0/mapper.root.html).

### Constraints

The constraints feature can be added either at an argument level directly into a `resources()` or other individual route call, or can be added as a chained function in it's own right. Constraints allow you to add regex to a route matching pattern, so you could for instance, have `/users/1/` and `/users/bob/` go to different controller actions.

```javascript
mapper()
   // users/1234
  .resources(name = "users", constraints = { key = "\d+" })
   // users/abc123
  .resources(name = "users", constraints = { key = "\w+\d+" })
.end();
```

Constraints can also be used as a wrapping function:

```javascript
mapper()
    .constraints( key = "\d+")
        .resources("users")
        .resources("cats")
        .resources("dogs")
    .end()
.end()
```

In this example, the `key` argument being made of digits only will apply to all the nested resources

### Wildcard Segments

Wildcard segments allow for wildcards to be used at any point in the URL pattern.

```javascript
mapper()
  // Match /user/anything/you/want
  .get(name="user/*[username]", to="users##search")
  // Match /user/anything/you/want/search/
  .get(name="user/*[username]/search", to="users##search")
.end()
```

In the above example, `anything/you/want` you gets set to the `params.username` including the `/`'s. The second example would require `/search/` to be on the end of the URL

### Shallow Resources

If you have a nested resource where you want to enforce the presence of the parent resource, but only on creation of that resource, then shallow routes can give you a bit of a short cut. An example might be Blog Articles, which have Comments. If we're thinking in terms of our models, let's say that Articles _Have Many_ Comments.

```javascript
mapper()
    .resources(name="articles", nested=true, shallow=true)
        .resources("comments")
        .resources("quotes")
        .resources("drafts")
    .end()
.end()
```

Without shallow routes, this block would create RESTful actions for all the nested resources, for example `/articles/[articleKey]/comments/[key]`

With Shallow resources, we can automatically put the `index`, `create` and `new` RESTful actions with the `ArticleKey` in the URL, but then separate out `edit`, `show`, `update` and `delete` actions into their own, and simpler URL path; When we edit or update a comment, we're doing it on that object as it's own entity, and the relationship to the parent article already exists.

So in this case, we get `index`, `new` and `create` with the `/articles/[articleKey]/` part in the URL, but to `show`, `edit`, `update` or `delete` a comment, we can just fall back to `/comments/`

### Member and Collection Blocks

A `member()` block is used within a nested resource to create routes which act 'on an object'; A member route will require an ID, because it _acts on_ a member. `photos/1/preview` is an example of a member route, because it acts on (and displays) a single object.

```javascript
mapper()
    // Create a route like `photos/1/preview`
    .resources(name="photos", nested=true)
        .member()
            .get("preview")
        .end()
    .end()
.end();
```

A collection route doesn't require an id because it acts on a collection of objects. `photos/search` is an example of a collection route, because it acts on (and displays) a collection of objects.

```javascript
mapper()
    // Create a route like `photos/search`
    .resources(name="photos", nested=true)
        .collection()
            .get("search")
        .end()
    .end()
.end();
```

### Redirection

As of Wheels 2.1, you can now use a `redirect` argument on `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` requests. This will execute before reaching any controllers, and perform a `302` redirect immediately after the route is matched.

CFScript

```javascript
mapper()
  .get(name="foo", redirect="https://www.google.com")
  .post(name="foo", redirect="https://www.google.com")
  .put(name="foo", redirect="https://www.google.com")
  .patch(name="foo", redirect="https://www.google.com")
  .delete(name="foo", redirect="https://www.google.com")
.end()
```

This is useful for the occasional redirect, and saves you having to create a dedicated controller filter or action just to perform a simple task. For large amounts of redirects, you may want to look into adding them at a higher level - e.g in an Apache VirtualHost configuration, as that will be more performant.

### Disabling automatic \[format] routes

{% hint style="info" %}
#### Note

Introduced in Wheels 2.1
{% endhint %}

By default, Wheels will add `.[format]` routes when using `resources()`. You may wish to disable this behavior to trim down the number of generated routes for clarity and performance reasons (or you just don't use this feature!).

You can either disable this via `mapFormat = false` on a per resource basis, or more widely, on a mapper basis:

```javascript
// For all chained calls
mapper(mapFormat=false)
.resources("users")
.end()

// or just for this resource
mapper()
.resources(mapFormat=false, name="users)
.end()
```

\
\
