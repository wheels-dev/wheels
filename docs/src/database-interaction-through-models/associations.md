---
description: >-
  Through some simple configuration, Wheels allows you to unlock some powerful
  functionality to use your database tables' relationships in your code.
---

# Associations

_Associations_ in Wheels allow you to define the relationships between your database tables. After configuring these relationships, doing pesky table joins becomes a trivial task. And like all other ORM functions in Wheels, this is done without writing a single line of SQL.

### 3 Types of Associations

In order to set up associations, you only need to remember 3 simple methods. Considering that the human brain only reliably remembers up to 7 items, we've left you with a lot of extra space. You're welcome. :)

The association methods should always be called in the `config()` method of a model that relates to another model within your application.

### The belongsTo Association

If your database table contains a field that is a foreign key to another table, then this is where to use the [belongsTo()](https://wheels.dev/api/v3.0.0/model.belongsto.html) function.

If we had a comments table that contains a foreign key to the posts table called `postid`, then we would have this `config()` method within our comment model:

{% code title="/app/models/comment.cfc" %}
```javascript
component extends="Model" {

    function config() {
        belongsTo("post");
    }

}
```
{% endcode %}

### The hasOne and hasMany Associations

On the other side of the relationship are the "has" functions. As you may have astutely guessed, these functions should be used according to the nature of the model relationship.

At this time, you need to be a little eccentric and talk to yourself. Your association should make sense in plain English language.

### An example of hasMany

So let's consider the `post / comment` relationship mentioned above for `belongsTo()`. If we were to talk to ourselves, we would say, "A post has many comments." And that's how you should construct your post model:

{% code title="/app/models/Post.cfc" %}
```javascript
component extends="Model" {

    function config() {
        hasMany("comments");
    }

}
```
{% endcode %}

You may be a little concerned because our model is called `comment` and not `comments`. No need to worry: Wheels understands the need for the plural in conjunction with the `hasMany()` method.

And don't worry about those pesky words in the English language that aren't pluralized by just adding an "s" to the end. Wheels is smart enough to know that words like "deer" and "children" are the plurals of "deer" and "child," respectively.

### An Example of hasOne

The [hasOne()](https://wheels.dev/api/v3.0.0/model.hasone.html) association is not used as often as the [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) association, but it has its use cases. The most common use case is when you have a large table that you have broken down into two or more smaller tables (a.k.a. denormalization) for performance reasons or otherwise.

Let's consider an association between `user` and `profile`. A lot of websites allow you to enter required info such as name and email but also allow you to add optional information such as age, salary, and so on. These can of course be stored in the same table. But given the fact that so much information is optional, it would make sense to have the required info in a `users` table and the optional info in a `profiles` table. This gives us a `hasOne()` relationship between these two models: "A user _has one_ profile."

In this case, our `profile` model would look like this:

{% code title="/app/models/profile.cfc" %}
```javascript
component extends="Model" {

    function config() {
        belongsTo("user");
    }

}
```
{% endcode %}

And our user model would look like this:

{% code title="/app/models/user.cfc" %}
```javascript
component extends="Model" {

    function config() {
        hasOne("profile");
    }

}
```
{% endcode %}

As you can see, you do not pluralize "profile" in this case because there is only one profile.

By the way, as you can see above, the association goes both ways, i.e. a `user hasOne() profile`, and a `profile belongsTo()` a `user`. Generally speaking, all associations should be set up this way. This will give you the fullest API to work with in terms of the methods and arguments that Wheels makes available for you.

However, this is not a definite requirement. Wheels associations are completely independent of one another, so it's perfectly OK to setup a [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) association without specifying the related [belongsTo()](https://wheels.dev/api/v3.0.0/model.belongsto.html) association.

### Dependencies

A dependency is when an associated model relies on the existence of its parent. In the example above, a `profile` is dependent on a `user`. When you delete the `user`, you would usually want to delete the `profile` as well.

Wheels makes this easy for you. When setting up your association, simply add the argument `dependent` with one of the following values, and Wheels will automatically deal with the dependency.

In your `model.cfc` file's `config()` function:

```javascript
// Instantiates the `profile` model and calls its `delete()` method.
hasOne(name="profile", dependent="delete");

// Quickly deletes the `profile` without instantiating it.
hasOne(name="profile", dependent="deleteAll");

// Sets the `userId` of the profile to `NULL`.
hasOne(name="profile", dependent="remove");

// Sets the `userId` of the profile to `NULL` (without instantiation).
hasOne(name="profile", dependent="removeAll");
```

You can create dependencies on `hasOne()` and `hasMany()` associations, but not `belongsTo()`.

### Self-Joins

It's possible for a model to be associated to itself. Take a look at the below setup where an employee belongs to a manager for example:

{% code title="/app/models/employee.cfc" %}
```javascript
component extends="Model" {

    function config() {
        belongsTo(name="manager", modelName="employee", foreignKey="managerId");
    }

}
```
{% endcode %}

Both the manager and employee are stored in the same `employees` table and share the same `Employee` model.

When you use this association in your code, the `employees` table will be joined to itself using the `managerid` column. Wheels will handle the aliasing of the (otherwise duplicated) table names. It does this by using the pluralized version of the name you gave the association (in other words "managers" in this case).

This is important to remember because if you, for example, want to select the manager's name, you will have to do so manually (Wheels won't do this for you, like it does with normal associations) using the `select` argument.

Here's an example of how to select both the name of the employee and their manager:

{% code title="/app/controllers/employees.cfc" %}
```javascript
component extends="Controller" {
 function index() {

   employees = model("employee").findAll(include="manager", select="employees.name, managers.name AS managerName");

 }
}
```
{% endcode %}

{% hint style="info" %}
#### Know Your Joins

Because the default `joinType` for `belongsTo()` is `inner`, employees without a manager assigned to them will not be returned in the `findAll()` call above. To return all rows you can set `jointype` to `outer` instead.
{% endhint %}

### Database Table Setup

Like everything else in Wheels, we strongly recommend a default naming convention for foreign key columns in your database tables.

In this case, the convention is to use the singular name of the related table with `id` appended to the end. So to link up our table to the `employees` table, the foreign key column should be named `employeeid`.

### Breaking the Convention

Wheels offers a way to configure your models to break this naming convention, however. This is done by using the `foreignKey` argument in your models' `belongsTo()` calls.

Let's pretend that you have a relationship between `author` and `post`, but you didn't use the naming convention and instead called the column `author_id`. (You just can't seem to let go of the underscores, can you?)

Your post's `config()` method would then need to look like this:

{% code title="/app/models/post.cfc" %}
```javascript
component extends="Model" {

    function config() {
        belongsTo(name="author", foreignKey="author_id");
    }

}
```
{% endcode %}

You can keep your underscores if it's your preference or if it's required of your application.

### Leveraging Model Associations in Your Application

Now that we have our associations set up, let's use them to get some data into our applications.

There are a couple ways to join data via associations, which we'll go over now.

### Using the include Argument in findAll()

To join data from related tables in our [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) calls, we simply need to use the include argument. Let's say that we wanted to include data about the author in our  [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) call for `posts`.

Here's what that call would look like:

{% code title="/app/controllers/posts.cfc" %}
```javascript
component extends="Controller" {
 function index() {

   posts = model("post").findAll(include="author");

 }
}
```
{% endcode %}

It's that simple. Wheels will then join the `authors` table automatically so that you can use that data along with the data from `posts`.

Note that if you switch the above statement around like this:

{% code title="/app/controllers/authors.cfc" %}
```javascript
component extends="Controller" {
 function index() {

  authors = model("author").findAll(include="posts");

 }
}
```
{% endcode %}

Then you would need to specify "post" in its plural form, "posts." If you're thinking about when to use the singular form and when to use the plural form, just use the one that seems most natural.

If you look at the two examples above, you'll see that in example #1, you're asking for all posts including each post's **author** (hence the singular "author"). In example #2, you're asking for all authors and all of the **posts** written by each author (hence the plural "posts").

You're not limited to specifying just one association in the `include` argument. You can for example return data for `authors`, `posts`, and `bios` in one call like this:

{% code title="/app/controllers/authors.cfc" %}
```javascript
component extends="Controller" {
 function index() {

   authorsPostsAndComments = model("author").findAll(include="posts,bio");

 }
}
```
{% endcode %}

To include several tables, simply delimit the names of the models with a comma. All models should contain related associations, or else you'll get a mountain of repeated data back.

### Joining Tables Through a Chain of Associations

When you need to include tables more than one step away in a chain of joins, you will need to start using parenthesis. Look at the following example:

{% code title="/app/controllers/comments.cfc" %}
```javascript
component extends="Controller" {
 function index() {

   commentsPostsAndAuthors = model("comment").findAll(include="post(author)");

 }
}
```
{% endcode %}

The use of parentheses above tells Wheels to look for an association named `author` on the `post` model instead of on the `comment` model. (Looking at the `comment` model is the default behavior when not using parenthesis.)

### Handling Column Naming Collisions

There is a minor caveat to this approach. If you have a column in both associated tables with the same name, Wheels will pick just one to represent that column.

In order to include both columns, you can override this behavior with the `select` argument in the finder functions.

For example, if we had a column named `name` in both your `posts` and `authors` tables, then you could use the `select` argument like so:

{% code title="/app/controllers/posts.cfc" %}
```javascript
component extends="Controller" {
    function index() {

        posts = model("post").findAll(
            select="posts.name, authors.id, authors.post_id, authors.name AS authorname",
            include="author"
        );

    }
}
```
{% endcode %}

You would need to hard-code all column names that you need in that case, which does remove some of the simplicity. There are always trade-offs!

### Using Dynamic Shortcut Methods

A cool feature of Wheels is the ability to use _dynamic shortcut_ methods to work with the models you have set up associations for. By dynamic, we mean that the name of the method depends on what name you have given the association when you set it up. By shortcut, we mean that the method usually delegates the actual processing to another Wheels method but gives you, the developer, an easier way to achieve the task (and makes your code more readable in the process).

As usual, this will make more sense when put into the context of an example. So let's do that right now.

### Example: Dynamic Shortcut Methods for Posts and Comments

Let's say that you tell Wheels through a [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) call that a `post` _has many_ `comments`. What happens then is that Wheels will enrich the post model by adding a bunch of useful methods related to this association.

If you wanted to get all `comments` that have been submitted for a `post`, you can now call `post.comments()`. In the background, Wheels will delegate this to a [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) call with the `where` argument set to `postid=#post.id#`.

### Listing of Dynamic Shortcut Methods

Here are all the methods that are added for the three possible association types.

**Methods Added by hasMany**

Given that you have told Wheels that a `post` _has many_ `comments` through a [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) call, here are the methods that will be made available to you on the `post` model.

Replace `[associationName]` below with the name of the associated model (i.e. `comments` in the case of the example that we're using here).

| Method         | Example                     | Description                                                                                                                                                                           |
| -------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [associationName]()          | post.comments()             | Returns all comments where the foreign key matches the post's primary key value. Similar to calling `model("comment").findAll(where="postid=#post.id#")`.                             |
| add[AssociationName]()       | post.addComment(comment)    | Adds a comment to the post association by setting its foreign key to the post's primary key value. Similar to calling `model("comment").updateByKey(key=comment.id, postid=post.id)`. |
| remove[AssociationName]()    | post.removeComment(comment) | Removes a comment from the post association by setting its foreign key value to `NULL`. Similar to calling `model("comment").updateByKey(key=comment.id, postid="")`.                 |
| delete[AssociationName]()    | post.deleteComment(comment) | Deletes the associated comment from the database table. Similar to calling `model("comment").deleteByKey(key=comment.id)`.                                                            |
| removeAll[AssociationName]() | post.removeAllComments()    | Removes all comments from the post association by setting their foreign key values to `NULL`. Similar to calling `model("comment").updateAll(postid="", where="postid=#post.id#")`.   |
| deleteAll[AssociationName]() | post.deleteAllComments()    | Deletes the associated comments from the database table. Similar to calling `model("comment").deleteAll(where="postid=#post.id#")`.                                                   |
| [associationName]Count()     | post.commentCount()         | Returns the number of associated comments. Similar to calling `model("comment").count(where="postid=#post.id#")`.                                                                     |
| new[AssociationName]()       | post.newComment()           | Creates a new comment object. Similar to calling `model("comment").new(postid=post.id)`.                                                                                              |
| create[AssociationName]()    | post.createComment()        | Creates a new comment object and saves it to the database. Similar to calling `model("comment").create(postid=post.id)`.                                                              |
| has[AssociationName]()       | post.hasComments()          | Returns true if the post has any comments associated with it. Similar to calling `model("comment").exists(where="postid=#post.id#")`.                                                 |
| findOne[AssociationName]()   | post.findOneComment()       | Returns one of the associated comments. Similar to calling `model("comment").findOne(where="postid=#post.id#")`.                                                                      |

**Methods Added by hasOne**

The [hasOne()](https://wheels.dev/api/v3.0.0/model.hasone.html) association adds a few methods as well. Most of them are very similar to the ones added by [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html).

Given that you have told Wheels that an `author` _has one_ `profile` through a [hasOne()](https://wheels.dev/api/v3.0.0/model.hasone.html) call, here are the methods that will be made available to you on the `author` model.

| Method      | Example                    | Description                                                                                                                                                                                                                                                                                               |
| ----------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [associationName]()       | author.profile()           | Returns the profile where the foreign key matches the author's primary key value. Similar to calling model("profile").findOne(where="authorid=#author.id#").                                                                                                                                              |
| set[AssociationName]()    | author.setProfile(profile) | Sets the profile to be associated with the author by setting its foreign key to the author's primary key value. You can pass in either a profile object or the primary key value of a profile object to this method. Similar to calling model("profile").updateByKey(key=profile.id, authorid=author.id). |
| remove[AssociationName]() | author.removeProfile()     | Removes the profile from the author association by setting its foreign key to NULL. Similar to calling model("profile").updateOne(where="authorid=#author.id#", authorid="").                                                                                                                             |
| delete[AssociationName]() | author.deleteProfile()     | Deletes the associated profile from the database table. Similar to calling model("profile").deleteOne(where="authorid=#author.id#")                                                                                                                                                                       |
| new[AssociationName]()    | author.newProfile()        | Creates a new profile object. Similar to calling model("profile").new(authorid=author.id).                                                                                                                                                                                                                |
| create[AssociationName]() | author.createProfile()     | Creates a new profile object and saves it to the database. Similar to calling model("profile").create(authorid=author.id).                                                                                                                                                                                |
| has[AssociationName]()    | author.hasProfile()        | Returns true if the author has an associated profile. Similar to calling model("profile").exists(where="authorid=#author.id#").                                                                                                                                                                           |

**Methods Added by belongsTo**

The [belongsTo()](https://wheels.dev/api/v3.0.0/model.belongsto.html) association adds a couple of methods to your model as well.

Given that you have told Wheels that a `comment` belongs to a `post` through a [belongsTo()](https://wheels.dev/api/v3.0.0/model.belongsto.html) call, here are the methods that will be made available to you on the `comment` model.

| Method   | Example           | Description                                                                                                                                 |
| -------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [associationName]()    | comment.post()    | Returns the post where the primary key matches the comment's foreign key value. Similar to calling model("post").findByKey(comment.postid). |
| has[AssociationName]() | comment.hasPost() | Returns true if the comment has a post associated with it. Similar to calling model("post").exists(comment.postid).                         |

One general rule for all of the methods above is that you can always supply any argument that is accepted by the method that the processing is delegated to. This means that you can, for example, call `post.comments(order="createdAt DESC")`, and the `order` argument will be passed along to `findAll()`.

Another rule is that whenever a method accepts an object as its first argument, you also have the option of supplying the primary key value instead. This means that `author.setProfile(profile)` will perform the same task as `author.setProfile(1)`. (Of course, we're assuming that the `profile` object in this example has a primary key value of `1`.)

### Performance of Dynamic Association Finders

You may be concerned that using a dynamic finder adds yet another database call to your application.

If it makes you feel any better, all calls in your Wheels request that generate the same SQL queries will be cached for that request. No need to worry about the performance implications of making multiple calls to the same `author.posts()` call in the scenario above, for example.

### Passing Arguments to Dynamic Shortcut Methods

You can also pass arguments to dynamic shortcut methods where applicable. For example, with the `[associationName]()` method, perhaps we'd want to limit a `post`'s comment listing to just ones created today. We can pass a `where` argument similar to what is passed to the `findAll()` function that powers `[associationName]()` behind the scenes.

```javascript
today = DateFormat(Now(), "yyyy-mm-dd");
comments = post.comments(where="createdAt >= '#today# 00:00:00'");
```

### Many-to-Many Relationships

We can use the same 3 association functions to set up many-to-many table relationships in our models. It follows the same logic as the descriptions mentioned earlier in this chapter, so let's jump right into an example.

Let's say that we wanted to set up a relationship between `customers` and `publications`. A `customer` can be subscribed to many `publications`, and `publications` can be subscribed to by many `customers`. In our database, this relationship is linked together by a third table called `subscriptions` (sometimes called a bridge entity by ERD snobs).

### Setting up the Models

Here are the representative models:

{% code title="/app/models/Customer.cfc" %}
```javascript
component extends="Model" {

    function config() {
        hasMany("subscriptions");
    }

}
```
{% endcode %}

{% code title="/app/models/Publication.cfc" %}
```javascript
component extends="Model" {

    function config() {
        hasMany("subscriptions");
    }

}
```
{% endcode %}

{% code title="/app/models/Subscription.cfc" %}
```javascript
component extends="Model" {

    function config() {
      belongsTo("customer");
      belongsTo("publication");
    }

}
```
{% endcode %}

This assumes that there are foreign key columns in `subscriptions` called `customerid` and `publicationid`.

### Using Finders with a Many-to-Many Relationship

At this point, it's still fairly easy to get data from the many-to-many association that we have set up above.

We can include the related tables from the `subscription` bridge entity to get the same effect:

{% code title="/app/controllers/subscriptions.cfc" %}
```javascript
component extends="Controller" {
 function index() {

   subscriptions = model("subscription").findAll(include="customer,publication");

 }
}
```
{% endcode %}

### Creating a Shortcut for a Many-to-Many Relationship

With the `shortcut` argument to [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html), you can have Wheels create a dynamic method that lets you bypass the join model and instead reference the model on the other end of the many-to-many relationship directly.

For our example above, you can alter the [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) call on the `customer` model to look like this instead:

{% code title="/app/models/customer.cfc" %}
```javascript
component extends="Model" {

 function config() {
    hasMany(name="subscriptions", shortcut="publications");
 }
}
```
{% endcode %}

Now you can get a customer's publications directly by using code like this:

{% code title="/app/controllers/customers.cfc" %}
```javascript
component extends="Controller" {
 function edit() {

   customer = model("customer").findByKey(params.key);
   publications = customer.publications();

 }
}
```
{% endcode %}

This functionality relies on having set up all the appropriate [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) and [belongsTo()](https://wheels.dev/api/v3.0.0/model.belongsto.html) associations in all 3 models (like we have in our example in this chapter).

It also relies on the association names being consistent, but if you have customized your association names, you can specify exactly which associations the shortcut method should use with the `through` argument.

The `through` argument accepts a list of 2 association names. The first argument is the name of the [belongsTo()](https://wheels.dev/api/v3.0.0/model.belongsto.html)association (set in the `subscription` model in this case), and the second argument is the [hasMany()](https://wheels.dev/api/v3.0.0/model.hasmany.html) association going back the other way (set in the `publication` model).

Sound complicated? That's another reason to stick to the conventions whenever possible: it keeps things simple.

### Are You Still with Us?

As you just read, Wheels offers a ton of functionality to make your life easier in working with relational databases. Be sure to give some of these techniques a try in your next Wheels application, and you'll be amazed at how little code that you'll need to write to interact with your database.
