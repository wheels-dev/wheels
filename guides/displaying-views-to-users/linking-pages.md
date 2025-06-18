---
description: >-
  Wheels does some magic to help you link to other pages within your app. Read
  on to learn why you'll rarely use an <a> tag ever again.
---

# Linking Pages

Wheels's built-in [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) function does all of the heavy lifting involved with linking the different pages of your application together. You'll generally be using [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) within your view code.

As you'll soon realize, the [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) function accepts a whole bunch of arguments. We won't go over all of them here, so don't forget to have a look at the [documentation](https://wheels.dev/api/v3.0.0/controller.linkto.html) for the complete details.

### Default Wildcard Linking

When installing Wheels, if you open the file at `app/config/routes.cfm`, you'll see something like this:

{% code title="app/config/routes.cfm" %}
```javascript
mapper()
    .wildcard()
    .root(method = "get")
.end();
```
{% endcode %}

The call to [wildcard()](https://wheels.dev/api/v3.0.0/mapper.wildcard.html) allows a simple linking structure where we can use the [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) helper to link to a combination of controller and action.

For example, if we had a `widgets` controller with a `new` action, we could link to it like this:

```html
#linkTo(text="New Widget", controller="widgets", action="new")#
```

That would generally produce this HTML markup:

```html
<a href="/widgets/new">New Widget</a>
```

### Linking to Routes

If you're developing a non-trivial Wheels application, you'll quickly grow out of the wildcard-based routing. You'll likely need to link to URLs containing primary keys, URL-friendly slugged titles, and nested subfolders. Now would be a good time to take a deep dive into the [Routing](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/routing) chapter and learn the concepts.

When you're using [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) to create links to routes, you need to pay attention to 2 pieces of information: the route _name_ and any _parameters_ that the route requires.

Let's work with a set of sample routes to practice creating links:

{% code title="app/config/routes.cfm" %}
```javascript
mapper()
    .get(name="newWidget", pattern="widgets/new", to="widgets##new")
    .get(name="widget", pattern="widgets/[key]", to="widgets##show")
    .get(name="widgets", to="widgets##index")
    .root(to="wheels##wheels")
.end();
```
{% endcode %}

With this in place, we can load the webroot of our application and click the "Routes" link in the debugging footer to get a list of our routes. You'll see information presented similarly to this:

| Name      | Method | Pattern         | Controller | Action |
| --------- | ------ | --------------- | ---------- | ------ |
| newWidget | GET    | /widgets/new    | widgets    | new    |
| widget    | GET    | /widgets/\[key] | widgets    | show   |
| widgets   | GET    | /widgets        | widgets    | index  |

(As you become more experienced, you'll be able look at `routes.cfm` and understand what the names and parameters are. Of course, this _Routes_ functionality is a great tool too.)

If we want to link to the routes named `newWidget` and `widgets`, it's fairly simple:

```html
#linkTo(text="All Widgets", route="widgets")#
#linkTo(text="New Widget", route="newWidget")#
```

As you can see, you create links by calling a method with the route name passed into the `route` argument. That will generate these links:

```html
<a href="/widgets">All Widgets</a>
<a href="/widgets/new">New Widget</a>
```

The `widget` route requires an extra step because it has that `[key]` parameter in its pattern. You can pass that parameter into `linkTo` as a named argument:

```html
#linkTo(text="The Fifth Widget", route="widget", key=5)#
```

That will produce this markup:

```html
<a href="/widgets/5">The Fifth Widget</a>
```

If you have a route with multiple parameters, you must pass all of the placeholders as arguments:

{% code title="Example" %}
```html
<!--- app/config/routes.cfm --->
<cfscript>
mapper()
    .get(
        name="widgetVariation",
        pattern="widgets/[widgetKey]/variations/[key].[format]",
        to="widgetVariations##show"
    )
.end();
</cfscript>

<!--- View file --->
<cfoutput>
#linkTo(
    text="A fine variation (PDF)",
    route="widgetVariation",
    widgetKey=5,
    key=20
    format="pdf"
)#
</cfoutput>

<!--- HTML generated --->
<a href="/widgets/5/variations/20.pdf">A fine variation (PDF)</a>
```
{% endcode %}

### Linking to Resources

Resources are the encouraged routing pattern in Wheels, and you will likely find yourself using this type of route most often.

Once you setup a resource in `app/config/routes.cfm`, the key is to inspect the routes generated and get a feel for the names and parameters that are expected.

Consider this sample `posts` resource:

{% code title="app/config/routes.cfm" %}
```javascript
mapper()
    .resources("posts")
.end();
```
{% endcode %}

We would see these linkable routes generated related to the posts. (See the chapter on [Form Helpers and Showing Errors](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/displaying-views-to-users/form-helpers-and-showing-errors) for information about posting forms to the rest of the routes.)

| Name     | Method | Pattern            | Controller | Action |
| -------- | ------ | ------------------ | ---------- | ------ |
| posts    | GET    | /posts             | posts      | index  |
| newPost  | GET    | /posts/new         | posts      | new    |
| editPost | GET    | /posts/\[key]/edit | posts      | edit   |
| post     | GET    | /posts/\[key]      | posts      | show   |

If we wanted to link to the various pages within that resource, we may write something like this on the index:

{% code title="app/views/posts/index.cfm" %}
```html
<nav class="global-nav">
    #linkTo(text="All Posts", route="posts")#
</nav>

<h1>Posts</h1>
<p>
    #linkTo(text="New Post", route="newPost")#
</p>

<ul>
    <cfloop query="posts">
        <li>
            #linkTo(text=posts.title, route="post", key=posts.id)#
            [#linkTo(text="Edit", route="editPost", key=posts.id)#]
        </li>
    </cfloop>
</ul>
```
{% endcode %}

The above code would generate markup like this:

```html
<nav class="global-nav">
    <a href="/posts">All Posts</a>
</nav>

<h1>Posts</h1>
<p>
    <a href="/posts/new">New Post</a>
</p>

<ul>
    <li>
        <a href="/posts/1">Some Title</a>
        [<a href="/posts/1/edit">Edit</a>]
    </li>
</ul>
```

### A Deep Dive into Linking and Routing

The [Routing](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/routing) chapter lists your options for generating URLs that are available in your application. Following is an explanation of how to link to the various types of routes available.

### Namespaces

Namespaces will generally add the namespace name to the beginning of the route.

Consider this namespace:

```javascript
mapper()
    .namespace("admin")
        .resources("roles")
    .end()
.end();
```

To link to the `roles` resource, you would prefix it with the namespace name:

```html
#linkTo(name="List Roles", route="adminRoles")#

#linkTo(text=role.title, route="adminRole", key=role.key())#
```

However, `new` and `edit` routes add the action name to the beginning of the route name:

```html
#linkTo(text="New Role", route="newAdminRole")#
#linkTo(text="Edit Role", route="editAdminRole", key=role.key())#
```

### Nested Resources

You have the ability to nest a resource within a resource like so:

```javascript
mapper()
    .resources(name="websites", nested=true)
        .resources("pages")
    .end()
.end();
```

To link to the `pages` resource, you add the parent resource's singular name first (e.g., the parent `website` is added, making the route name `websitePage`):

```html
<!---
    Also notice that the parent route's primary key parameter is
    `websiteKey`:
--->
#linkTo(text="All Pages", route="websitePages", websiteKey=website.key())#

#linkTo(text="New Page", route="newWebsitePage", websiteKey=website.key())#

<!--- And the child resource's primary key parameter is `key`: --->
#linkTo(
    text="Show Page",
    route="websitePage",
    websiteKey=website.key(),
    key=page.key()
)#

#linkTo(
    text="Edit Page",
    route="editWebsitePage",
    websiteKey=website.key(),
    key=page.key()
)#
```

### Linking to a Delete Action

Wheels 2.0 introduced security improvements for actions that change data in your applications (i.e., creating, updating, and deleting database records). Wheels protects these actions by requiring that they happen along with a form `POST` in the browser.

A common UI pattern is to have a link to delete a record, usually in an admin area. Unfortunately, links can only trigger `GET` requests, so we need to work around this.

To link to a delete request's required `DELETE` method, we need to code the link up as a simple form with submit button:

```html
#buttonTo(
    text="Delete",
    route="category",
    key=category.key(),
    method="delete",
    inputClass="button-as-link"
)#
```

The [buttonTo()](https://wheels.dev/api/v3.0.0/controller.buttonto.html) helper generates a form with submit button. As you can see from the example, you can style the submit button itself by prepending any arguments with `input` (e.g., `inputClass`).

Then it is up to you to style the form and submit button to look like a link or button using CSS (using whatever `class`es that you prefer in your markup, of course).

If you need even more control, you can code up your own [startFormTag()](https://wheels.dev/api/v3.0.0/controller.startformtag.html) with whatever markup that you like. Just be sure to pass `method="delete"` to the call to `startFormTag`.

By the way, this will work with any request method that you please: `post`, `patch`, and `put` as well as `delete`.

### Extreme Example

If we were to use all of the parameters for [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html), our code may look something like this:

```html
#linkTo(
    text='<i class="rock-fist"></i> Wheels Rocks!',
    route="wheelsRocks",
    key=55,
    params="rocks=yes&referral=wheels.dev",
    anchor="rockin",
    host="www.example.co.uk",
    protocol="https",
    onlyPath=false,
    encode="attributes"
)#
```

Which would generate this HTML (or something like it):

```html
<a href="https://www.example.co.uk/wheels/rocks/55?rocks=yes&amp;amp;referral=wheels.dev#rockin"><i class="rock-fist"></i> Wheels Rocks!</a>
```

### Images and Other Embedded HTML in Link Texts

If you'd like to use an image as a link to another page, pass the output of [imageTag()](https://wheels.dev/api/v3.0.0/controller.imagetag.html) to the `text` argument of [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html)and use the `encode` argument to instruct `linkTo` to only encode `attributes`:

```html
#linkTo(
    text=imageTag(source="authors.jpg"),
    route="blogAuthors",
    encode="attributes"
)#
```

You can also use your CFML engine's built-in string interpolation to embed other HTML into the link text in a fairly readable manner:

```html
#linkTo(
    text='<i class="fa fa-user"></i> #EncodeForHtml(employees.fullName)#',
    route="employee",
    key=employees.id,
    encode="attributes"
)#
```

{% hint style="danger" %}
#### Security Notice

If you decide to opt out of encoding, be careful. Any dynamic data passed in to un-encoded values should be escaped manually using your CFML engine's `EncodeForHtml()` function.
{% endhint %}

### Adding Additional Attributes Like class, rel, and id

Like many of the other Wheels view helpers, any additional arguments that you pass to [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) will be added to the generated `<a>` tag as attributes.

For example, if you'd like to add a `class` attribute value of button to your link, here's what the call to [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) would look like:

```
#linkTo(text="Check Out", route="checkout", class="button")#
```

The same goes for any other argument that you pass, including but not limited to `id, rel, onclick`, etc.

### What If I Don't Have URL Rewriting Enabled?

Wheels will handle linking to pages without URL rewriting for you automatically. Let's pretend that you still have Wheels installed in your site root, but you do not have URL rewriting on. How you write your [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) call will not change:

```
#linkTo(
    text="This link isn't as pretty, but it still works",
    route="product",
    key=product.key()
)#
```

Wheels will still correctly build the link markup:

```html
<a href="/index.cfm/products/3">This link isn't as pretty, but it still works</a>
```

### Linking in a Subfolder Deployment of Wheels

The same would be true if you had Wheels installed in a subfolder, thus perhaps eliminating your ability to use [URL Rewriting](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/handling-requests-with-controllers/url-rewriting) (depending on what web server you have). The same [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) code above may generate this HTML if you had Wheels installed in a subfolder called `foo`:

```html
<a
    href="/foo/index.cfm?route=product&amp;key=3">
    This link isn't as pretty, but it still works
</a>
```

### Use the linkTo() Function for Portability

An `<a>` tag is easy enough, isn't it? Why would we need to use a function to do this mundane task? It turns out that there are some advantages. Here's the deal.

Wheels gives you a good amount of structure for your applications. With this, instead of thinking of URLs in the "old way," we think in terms of what route we're sending the user to.

What's more, Wheels is smart enough to build URLs for you. And it'll do this for you based on your situation with URL rewriting. Are you using URL rewriting in your app? Great. Wheels will build your URLs accordingly. Not fortunate enough to have URL rewriting capabilities in your development or production environments? That's fine too because Wheels will handle that automatically. Are you using Wheels in a subfolder on your site, thus eliminating your ability to use URL rewriting? Wheels handles that for you too.

If you see the pattern, this gives your application a good deal of portability. For example, you could later enable URL rewriting or move your application to a different subfolder. As long as you're using [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) to build your links, you won't need to change anything extra to your code in order to accommodate this change.

Lastly, if you later install a [plugin](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/plugins/installing-and-using-plugins) that needs to modify link markup, that plugin's hook is the [linkTo()](https://wheels.dev/api/v3.0.0/controller.linkto.html) helper.

Oh, and another reason is that it's just plain cool too. ;)
