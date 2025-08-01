---
description: >-
  Generate extra properties in your models on the fly without needing to store
  redundant data in your database.
---

# Calculated Properties

### Working within CFML's Constraints to Deliver OOP-like Functionality

Wheels makes up for the slowness of arrays of objects in CFML by providing _calculated properties_. With calculated properties, you can generate additional properties on the fly based on logic and data within your database.

### Example #1: Full Name

Consider the example of `fullName`. If your database table has fields for `firstName` and `lastName`, it wouldn't make sense to store a third column called `fullName`. This would require more storage for redundant data, and it would add extra complexity that could lead to bugs and maintenance problems in the future.

#### Traditional Object-Oriented Calculations

In most object-oriented languages, you would add a method to your class called `getFullName()`, which would return the concatenation of `this.firstName & " " & this.lastName`. The `getFullName()` method could potentially provide arguments to list the last name first and other types of calculations or transformations as well.

Wheels still allows for you to do this sort of dynamic calculation with the `returnAs="objects"` argument in methods like [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html), but we advise against it when fetching large data sets because of the slowness of `CreateObject()` across CFML engines.

See the chapter on [Reading Records](https://wheels.dev/3.0.0/guides/database-interaction-through-models/reading-records) for more information.

#### Using Calculated Properties to Generate fullName in the Database at Runtime

As an alternative, you can set up a calculated property that dynamically performs the concatenation at the database level. In our example, we would write a line similar to this in our model's `config()` method:

```javascript
property(
        name="fullName",
        sql="RTRIM(LTRIM(ISNULL(users.firstname, '') + ' '
            + ISNULL(users.lastname, '')))"
    );
```

As you can probably deduce, we're creating a SQL statement that will be run in the `SELECT` clause to generate the \`fullName.

With this line in place, `fullName` will become available in both full model objects and query objects returned by the various finder methods like [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) and [findOne()](https://wheels.dev/api/v3.0.0/model.findone.html).

### Example #2: Age

Naturally, if you store the user's birth date in the database, your application can use that data to dynamically calculate the user's age. Your app always knows how many years old the user is without needing to explicitly store his or her age.

#### Creating the Calculated Property for Age

In order to calculate an extra property called `age` based on the `birthDate` column, our calculated property in `config()` may look something like this:

Example Code

```javascript
property(
        name="age",
        sql="(CAST(CONVERT(CHAR(8), GETDATE(), 112) AS INT)
            - CAST(CONVERT(CHAR(8), users.date_of_birth, 112) AS INT))
            / 10000"
);
```

Much like the `fullName` example above, this will cause the database to add a property called `age` storing the user's age as an integer.

Note that the cost to this approach is that you may need to introduce DBMS-specific code into your models. This may cause problems when you need to switch DBMS platforms, but at least all of this logic is isolated into your model CFCs.

#### Using the New age Property for Other Database Calculations

Calculated properties don't end at just generating extra properties. You can now also use the new property for additional calculations:

* Creating additional properties with the `select` argument
* Additional `where` clause calculations
* Record sorting with `order`
* Pagination
* And so on…

For example, let's say that we only want to use `age` to return users who are in their 20s. We can use the new `age`property as if it existed in the database table. For extra measure, let's also sort the results from oldest to youngest.

Example Code

```javascript
users = model("user").findAll(
        where="age >= 20 AND age < 30", order="age DESC"
);
```

### Specifying a Data Type

By default, calculated properties will return `char` as the column data type. Whilst this covers most scenarios, if you want to return something like a date, it can be problematic. Thankfully we can just specify a `dataType` argument to return the appropriate data type.

```javascript
property(
  name="createdAtAlias",
  sql="posts.createdat", 
  dataType="datetime"
);
```
