---
description: >-
  An overview of Object Relational Mapping (ORM) and how is it used in Wheels.
  Learn how ORM simplifies your database interaction code.
---

# Object Relational Mapping

Mapping objects in your application to records in your database tables is a key concept in Wheels. Let's take a look at exactly how this mapping is performed.

### Class and Object Methods

Unlike most other languages, there is no notion of class level (a.k.a. "static") methods in CFML. This means that even if you call a method that does not need to use any instance data, you still have to create an object first.

In Wheels, we create an object like this:

```javascript
model("author");
```

The built-in Wheels [model()](https://wheels.dev/api/v3.0.0/controller.model.html) function will return a reference to an `author` object in the `application` scope (unless it's the first time you call this function, in which case it will also create and store it in the `application` scope).

Once you have the `author` object, you can start calling class methods on it, like [findByKey()](https://wheels.dev/api/v3.0.0/model.findbykey.html), for example. [findByKey()](https://wheels.dev/api/v3.0.0/model.findbykey.html) returns an instance of the object with data from the database record defined by the key value that you pass.

Obviously, `author` is just an example here, and you'll use the names of the `.cfc` files you have created in the `/app/models` folder.

```javascript
authorClass = model("author");
authorObject = authorClass.findByKey(1);
```

For readability, this is usually combined into the following:

```javascript
authorObject = model("author").findByKey(1);
```

Now `authorObject` is an instance of the `Author` class, and you can call object level methods on it, like [update()](https://wheels.dev/api/v3.0.0/model.update.html) and [save()](https://wheels.dev/api/v3.0.0/model.save.html).

```javascript
authorObject.update(firstName="Joe");
```

In this case, the above code updates `firstName` field of the `author` record with a primary key value of `1` to `Joe`.

### Primary Keys

Traditionally in Wheels, a primary key is usually named `id`, it increments automatically, and it's of the `integer` data type. However, Wheels is very flexible in this area. You can setup your primary keys in practically any way you want to. You can use _natural_ keys (`varchar`, for example), _composite keys_ (having multiple columns as primary keys), and you can name the key(s) whatever you want.

You can also choose whether the database creates the key for you (using auto-incrementation, for example) or create them yourself directly in your code.

What's best, Wheels will introspect the database to see what choices you have made and act accordingly.

### Tables and Classes

Wheels comes with a custom built ORM. ORM stands for "Object-Relational Mapping" and means that tables in your relational database map to classes in your application. The records in your tables map to objects of your classes, and the columns in these tables map to properties on the objects.

To create a class in your application that maps to a table in your database, all you need to do is create a new class file in your `/app/models` folder and make it extend the `Model.cfc` file.

```javascript
component extends="Model" {
}
```

If you don't intend to create any custom methods in your class, you can actually skip this step and just call methods without having a file created. It will work just as well. As your application grows, you'll probably want to have your own methods though, so remember the `/app/models` folder. That's where they'll go.

Once you have created the file (or deliberately chosen not to for now), you will have a bunch of methods available handle reading and writing to the `authors` table. (For the purpose of showing some examples, we will assume that you have created a file named `Author.cfc`, which will then be mapped to the `authors` table in the database).

For example, you can write the following code to get the author with the primary key of `1`, change his first name, and save the record back to the database.

```javascript
auth = model("author").findByKey(1);
auth.firstName = "Joe";
auth.save();
```

This code makes use of the class method [findByKey()](https://wheels.dev/api/v3.0.0/model.findbykey.html), updates the object property in memory, and then saves it back to the database using the object method [save()](https://wheels.dev/api/v3.0.0/model.save.html). We'll get back to all these methods and more later.

### Table and CFC Naming

By default, a table name should be the plural version of the class name. So if you have an `Author.cfc` class, the table name should be `authors`.

To change this behavior you can use the [table()](https://wheels.dev/api/v3.0.0/model.table.html) method. This method call should be placed in the `config()` method of your class file, which is where all configuration of your model is done.

So, for example, if you wanted for your `author` model to map to a table in your database named `tbl_authors`, you would add the following code to the `config()` method:

```javascript
component extends="Model" {
    function config() {
    table("tbl_authors");
  }
}
```

### Models Without Database Tables

Most of the time, you will want to have your model mapped to a database table. However, it is possible to skip this requirement with a simple setting:

```javascript
function config() {
    table(false);
}
```

With that in place, you have the foundation for a model that never touches the database. When you call methods like [save()](https://wheels.dev/api/v3.0.0/model.save.html), [create()](https://wheels.dev/api/v3.0.0/model.create.html), [update()](https://wheels.dev/api/v3.0.0/model.update.html), and [delete()](https://wheels.dev/api/v3.0.0/model.delete.html) on a tableless model, the entire model lifecycle will still run, including object validation and object callbacks.

Typically, you will want to configure properties and validations manually for tableless models and then override [save()](https://wheels.dev/api/v3.0.0/model.save.html) and other persistence methods needed by your application to persist with the data elsewhere (maybe in the `session` scope, an external NoSQL database, or as an email sent from a contact form).

Features supported:

- Properties
- Validations
- Callbacks involving initialisation and validations

See [Building search forms with tableless models in Wheels](https://wheels.dev/blog/building-search-forms-with-tableless-models-in-wheels) for a worked-out example.

### Columns and Properties

Objects in Wheels have properties that correspond to the columns in the table that it maps to. The first time you call a method on a model, Wheels will reflect on the schema inside the database for the table the class maps to and extract all the column information.

{% hint style="warning" %}
#### Note about database permissions

In order for Wheels to successfully read all schema data from your database be sure the data source user has the required access for your DBMS. For example, Microsoft SQL Server requires the "ddl\_admin" permission for some meta data such as column defaults.
{% endhint %}

To keep things as simple as possible, there are no getters or setters in Wheels. Instead, all the properties are made available in the `this` scope.

If you want to map a specific property to a column with a different name, you can override the Wheels mapping by using the [property()](https://wheels.dev/api/v3.0.0/model.property.html) method like this:

```javascript
component extends="Model" {
    function config() {
    property(name="firstName", column="tbl_auth_f_name");
  }
}
```

### Blank Strings and NULL Values

Since there is no concept of `null` / `nil` in CFML, Wheels will assume that when you save a blank string to the database it should be converted to `NULL`.

For this reason we recommend that you avoid having blank strings stored in the database (since there is no way to distinguish them from `NULL` values once they've been mapped to a Wheels object / result set).
