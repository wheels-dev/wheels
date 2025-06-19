---
description: Updating records in your database tables.
---

# Updating Records

When you have created or retrieved an object, you can save it to the database by calling its [save()](https://wheels.dev/api/v3.0.0/model.save.html) method. This method returns `true` if the object passes all validations and the object was saved to the database. Otherwise, it returns `false`.

This chapter will focus on how to update records. Read the [Creating Records](https://guides.wheels.dev/2.5.0/v/3.0.0-snapshot/database-interaction-through-models/creating-records) chapter for more information about how to create new records.

### A Practical Example

Let's start with an example of getting a blog post from the database, updating its title, and saving it back:

```javascript
post = model("post").findByKey(33);
post.title = "New version of Wheels just released";
post.save();
```

You can also change the values of one or more properties and save them to the database in one single call using the `update()` method, like this:

```javascript
post = model("post").findByKey(33);
post.update(title="New version of Wheels just released");
```

### Updating Via struct Values

You can also pass in name/value pairs to `update()` as a struct. The main reason this method accepts a struct is to allow you to easily use it with forms.

This is how it would look if you wanted to update the properties for a post based on a submitted form.

```javascript
post = model("post").findByKey(params.key);
post.update(params.post);
```

It's also possible to combine named arguments with a struct, but then you need to name the struct argument as `properties`.

Example:

```javascript
post = model("post").findByKey(params.key);
post.update(title="New version of Wheels just released", properties=params.post);
```

### Combine Reading and Updating into a Single Call

To cut down even more on lines of code, you can also combine the reading and saving of the objects by using the class-level methods [updateByKey()](https://wheels.dev/api/v3.0.0/model.updatebykey.html) and [updateAll()](https://wheels.dev/api/v3.0.0/model.updateall.html).

### The updateByKey() Method

Give the [updateByKey()](https://wheels.dev/api/v3.0.0/model.updatebykey.html) method a primary key value (or several if you use composite keys) in the `key` argument, and it will update the corresponding record in your table with the properties you give it. You can pass in the properties either as named arguments or as a struct to the `properties` argument.

This method returns the object with the primary key value you specified. If the object does not pass validation, it will be returned anyway, but nothing will be saved to the database.

By default, [updateByKey()](https://wheels.dev/api/v3.0.0/model.updatebykey.html) will fetch the object first and call the `update()` method on it, thus invoking any callbacks and validations you have specified for the model. You can change this behavior by passing in `instantiate=false`. Then it will just update the record from the table using a simple UPDATE query.

An example of using [updateByKey()](https://wheels.dev/api/v3.0.0/model.updatebykey.html) by passing a struct:

```javascript
result = model("post").updateByKey(33, params.post);
```

And an example of using [updateByKey()](https://wheels.dev/api/v3.0.0/model.updatebykey.html) by passing named arguments:

```javascript
result = model("post").updateByKey(id=33, title="New version of Wheels just released", published=1);
```

### Updating Multiple Rows with updateAll()

The [updateAll()](https://wheels.dev/api/v3.0.0/model.updateall.html) method allows you to update more than one record in a single call. You specify what records to update with the `where` argument and tell Wheels what updates to make using named arguments for the properties.

The `where` argument is used exactly as you specify it in the `WHERE` clause of the query (with the exception that Wheels automatically wraps everything properly in `cfqueryparam` tags). So make sure that you place those commas and quotes correctly!

An example:

```javascript
recordsReturned = model("post").updateAll(
        published=1, publishedAt=Now(), where="published=0"
);
```

Unlike [updateByKey()](https://wheels.dev/api/v3.0.0/model.updatebykey.html), the [updateAll()](https://wheels.dev/api/v3.0.0/model.updateall.html) method will not instantiate the objects by default. That could be really slow if you wanted to update a lot of records at once.
