---
description: >-
  Use Wheels to get statistics on the values in a column, like row counts,
  averages, highest values, lowest values, and sums.
---

# Column Statistics

Since Wheels simplifies so much for you when you select, insert, update, and delete rows from the database, it would be a little annoying if you had to revert back to using `cfquery` and `COUNT(id) AS x` type queries when you wanted to get aggregate values, right?

Well, good news. Of course you don't need to do this; just use the built-in functions [sum()](https://api.wheels.dev/model.sum.html), [minimum()](https://api.wheels.dev/model.minimum.html), [maximum()](https://api.wheels.dev/model.maximum.html), [average()](https://api.wheels.dev/model.average.html) and [count()](https://api.wheels.dev/model.count.html).

Let's start with the [count()](https://api.wheels.dev/model.count.html) function, shall we?

### Counting Rows

To count how many rows you have in your `authors` table, simply do this:

```javascript
authorCount = model("author").count();
```

What if you only want to count authors with a last name starting with "A"? Like the [findAll()](https://api.wheels.dev/model.findall.html) function, [count()](https://api.wheels.dev/model.count.html) will accept a `where` argument, so you can do this:

```javascript
authorCount = model("author").count(where="lastName LIKE 'A%'");
```

Simple enough. But what if you wanted to count only authors in the USA, and that information is stored in a different table? Let's say you have stored country information in a table called `profiles` and also setup a `hasOne` / `belongsTo` association between the `author` and `profile` models.

Just like in the [findAll()](https://api.wheels.dev/model.findall.html) function, you can now use the `include` argument to reference other tables.

In our case, the code would end up looking something like this:

```javascript
authorCount = model("author").count(include="profile", where="countryId=1 AND lastName LIKE 'A%'");
```

Or, if you care more about readability than performance, why not just join in the `countries` table as well?

```javascript
authorCount = model("author").count(include="profile(country)", where="name='USA' AND lastName LIKE 'A%'");
```

In the background, these functions all perform SQL that looks like this:

{% code title="MySQL" %}
```sql
SELECT COUNT(*)
FROM authors
WHERE ...
```
{% endcode %}

However, if you include a `hasMany` association, Wheels will be smart enough to add the `DISTINCT` keyword to the SQL. This makes sure that you're only counting unique rows.

For example, the following method call:

```javascript
authorCount = model("author").count(include="books", where="title LIKE 'Wheels%'");
```

Will execute this SQL (presuming `id` is the primary key of the `authors` table and the correct associations have been setup):

{% code title="MySQL" %}
```sql
SELECT COUNT(DISTINCT authors.id)
FROM authors LEFT OUTER JOIN books ON authors.id = books.authorid
WHERE ..
```
{% endcode %}

OK, so now we've covered the [count()](https://api.wheels.dev/model.count.html) function, but there are a few other functions you can use as well to get column statistics.

### Getting an Average

You can use the [average()](https://api.wheels.dev/model.average.html) function to get the average value on any given column. The difference between this function and the [count()](https://api.wheels.dev/model.count.html) function is that this operates on a single column, while the [count()](https://api.wheels.dev/model.count.html) function operates on complete records. Therefore, you need to pass in the name of the property you want to get an average for.

The same goes for the remaining column statistics functions as well; they all accept the `property` argument.

Here's an example of getting the average salary in a specific department:

```javascript
avgSalary = model("employee").average(property="salary", where="departmentId=1");
```

You can also pass in `distinct=true` to this function if you want to include only each unique instance of a value in the average calculation.

### Getting the Highest and Lowest Values

To get the highest and lowest values for a property, you can use the [minimum()](https://api.wheels.dev/model.minimum.html) and [maximum()](https://api.wheels.dev/model.maximum.html) functions.

They are pretty self explanatory, as you can tell by the following examples:

```javascript
highestSalary = model("employee").maximum("salary");
lowestSalary = model("employee").minimum("salary");
```

### Getting the Sum of All Values

The last of the column statistics functions is the [sum()](https://api.wheels.dev/model.sum.html) function.

As you have probably already figured out, [sum()](https://api.wheels.dev/model.sum.html) adds all values for a given property and returns the result. You can use the same arguments as with the other functions (`property, where, include`, and `distinct`).

Let's wrap up this chapter on a happy note by getting the total dollar amount you've made:

```javascript
howRichAmI = model("invoice").sum("billedAmount");
```

### Grouping Your Results

All of the methods we've covered in this chapter accepts the `group` argument. Let's build on the example with getting the average salary for a department above, but this time, let's get the average for all departments instead.

```javascript
avgSalaries = model("employee").average(property="salary", group="departmentId");
```

When you choose to group results like this you get a `cfquery` result set back, as opposed to a single value.

{% hint style="info" %}
#### Limited Support

The `group` argument is currently only supported on SQL Server and MySQL databases.
{% endhint %}
