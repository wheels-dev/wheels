---
description: How to create new objects and save them to the database.
---

# Creating Records

In Wheels, one way to create objects that represent records in our table is by calling the [new()](https://api.wheels.dev/model.new.html) class-level method.

```javascript
newAuthor = model("author").new();
```

We now have an empty `Author` object that we can start filling in properties for. These properties correspond with the columns in the `authors` database table, unless you have mapped them specifically to columns with other names (or mapped to an entirely different table).

```javascript
newAuthor.firstName = "John";
newAuthor.lastName = "Doe";
```

At this point, the `newAuthor` object only exists in memory. We save it to the database by calling its [save()](https://api.wheels.dev/model.save.html) method.

```javascript
newAuthor.save();
```

### Creating Based on a Struct

If you want to create a new object based on parameters sent in from a form request, the [new()](https://api.wheels.dev/model.new.html) method conveniently accepts a struct as well. As we'll see later, when you use the Wheels form helpers, they automatically turn your form variables into a struct that you can pass into [new()](https://api.wheels.dev/model.new.html) and other methods.

Given that `params.newAuthor` is a struct containing the `firstName` and `lastName` variables, the code below does the same as the code above (without saving it though).

```javascript
newAuthor = model("author").new(params.newAuthor);
```

### Saving Straight to the Database

If you want to save a new author to the database right away, you can use the [create()](https://api.wheels.dev/model.create.html) method instead.

{% code title="" %}
```javascript
model("author").create(params.newAuthor);
```
{% endcode %}

### The Primary Key

Note that if we have opted to have the database create the primary key for us (which is usually done by auto-incrementing it), it will be available automatically after the object has been saved.

This means you can read the value by doing something like this. (This example assumes you have an auto-incrementing `integer` column named `id` as the primary key.)

```javascript
<cfscript>
newAuthor = model("author").new();
newAuthor.firstName = "Joe";
newAuthor.lastName = "Jones";
newAuthor.save();
</cfscript>
<cfoutput>#newAuthor.id#</cfoutput>
```

Don't forget that you can name your primary key whatever you want, and you can even use composite keys, natural keys, non auto-incrementing, and so on.

No matter which method you prefer, Wheels will use database introspection to see how your table is structured and act accordingly.

### Using Database Defaults

The best way of handling model defaults is usually by setting a default constraint in your database. When Wheels saves the model to the database, it will automatically insert the default value if you haven't provided one within your model.

However, unlike the primary key, Wheels will not automatically load database defaults after saving as it requires an additional database call and in most cases is not required. (After saving, the most common action is to redirect, in which case you would reload the newly saved model in the next request anyway.)

Of course, if you do need to access the database default immediately after saving, Wheels allows this. Simply add `reload=true` to the [create()](https://api.wheels.dev/model.create.html), [update()](https://api.wheels.dev/model.update.html), or [save()](https://api.wheels.dev/model.save.html) methods:

```javascript
newAuthor = model("author").new();
newAuthor.firstName = "Joe";
newAuthor.lastName = "Jones";
newAuthor.save(reload=true);
```

### Using Model Defaults

Sometimes a database default isn't the most appropriate solution because the value is only set after the model has been inserted. If you want to set a default value when it is first created with [new()](https://api.wheels.dev/model.new.html) or [create()](https://api.wheels.dev/model.create.html), then you can pass the `defaultValue` argument of the [property()](https://api.wheels.dev/model.property.html) method used in your model's `config()` block.

```javascript
property(name="welcomeText", defaultValue="Hello world!");
```

This is effectively the same as doing this:

```javascript
model("myModel").new(welcomeText="Hello world!");
```

..except you only need to set it once per model.
