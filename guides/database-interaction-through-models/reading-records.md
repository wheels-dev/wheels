---
description: Returning records from your database tables as objects or queries.
---

# Reading Records



Reading records from your database typically involves using one of the 3 finder methods available in Wheels: [findByKey()](https://api.wheels.dev/model.findbykey.html), [findOne()](https://api.wheels.dev/model.findone.html), and [findAll()](https://api.wheels.dev/model.findall.html).

The first 2 of these, [findByKey()](https://api.wheels.dev/model.findbykey.html) and [findOne()](https://api.wheels.dev/model.findone.html), return an object, while the last one, findAll(), returns the result from a `cfquery` tag.

### Fetching a Row by Primary Key Value

Let's start by looking at the simplest of the finder methods, [findByKey()](https://api.wheels.dev/model.findbykey.html). This method takes one argument: the primary key (or several keys if you're using composite keys) of the record you want to get.

If the record exists, it is returned to you as an object. If not, Wheels will return the boolean value `false`.

In the following example, we assume that the `params.key` variable has been created from the URL (for example a URL such as `http://localhost/blog/viewauthor/7`.)

In your controller:

```javascript
author = model("author").findByKey(params.key);
if(!IsObject(author)){
    flashInsert(message="Author #params.key# was not found");
  redirectTo(back=true);
}
```

In your view:

```html
<cfoutput>Hello, #author.firstName# #author.lastName#!</cfoutput>
```

### Fetching a Row by a Value Other Than the Primary Key

Often, you'll find yourself wanting to get a record (or many) based on a criteria other than just the primary key value.

As an example, let's say that you want to get the last order made by a customer. You can achieve this by using the `findOne()` method like so:

```javascript
anOrder = model("order").findOne(order="datePurchased DESC");
```

### Fetching Multiple Rows

You can use [findAll()](https://api.wheels.dev/model.findall.html) when you are asking to get one or more records from the database. Wheels will return this as a `cfquery` result (which could be empty if nothing was found based on your criteria).

### Arguments for findOne() and findAll()

Besides the difference in the default return type, [findOne()](https://api.wheels.dev/model.findone.html) and [findAll()](https://api.wheels.dev/model.findall.html) accept the same arguments. Let's have a closer look at these arguments.

### select Argument

This maps to the `SELECT` clause of the SQL statement.

Wheels is pretty smart when it comes to figuring out what to select from the database table(s). For example, if nothing is passed in to the `select` argument, Wheels will assume that you want all columns returned and create a `SELECT`clause looking something like this:

```javascript
artists.id,artists.name
```

As you can see, Wheels knows that the `artist` model is mapped to the `artists` table and will prepend the table name to the column names accordingly.

If you have mapped columns to a different property name in your application, Wheels will take this into account as well. The end result then could look like this:

```
artists.id,artists.fname AS firstName
```

If you select from more than one table (see the `include` argument below) and there are ambiguous column names, Wheels will sort this out for you by prepending the model name to the column name.

Let's say you have a column called `name` in both the `artists` and `albums` tables. The `SELECT` clause will be created like this:

```
artists.name,albums.name AS albumName
```

If you use the include argument a lot, you will love this feature as it saves a lot of typing.

If you don't want to return all properties, you can override this behavior by passing in a list of the properties you want returned.

If you want to take full control over the `SELECT` clause, you can do so by specifying the table names (i.e. `author.firstName`) in the `select` argument or by using alias names (i.e., `firstname AS firstName`). If Wheels comes across the use of any of these techniques, it will assume you know what you're doing and pass on the select argument straight to the `SELECT` clause with no changes.

A tip is to turn on debugging when you're learning Wheels so you can get a good understanding of how Wheels creates the SQL statements.

### where Argument

This maps to the `WHERE` clause of the SQL statement. Wheels will also convert all your input to `cfqueryparam` tags for you automatically.

There are some limitations to what you can use in the `where` argument, but the following SQL will work: `=, !=, <>, <, <=, >, >=, LIKE, NOT LIKE, IN, NOT IN, IS NULL, IS NOT NULL, AND,` and `OR`. (Note that it's a requirement to write SQL keywords in upper case.) In addition to this, you can use parentheses to group conditional SQL statements together.

It's worth mentioning that although Wheels does not support the `BETWEEN` operator, you can get around this by using `>=` and `<=`.

Example with numeric value:

```javascript
items = model("item").findAll(where="price >= 100 AND price <= 500");
```

The same goes for `NOT BETWEEN`:

```javascript
items = model("item").findAll(where="price <= 100 OR price >= 500");
```

In Wheels ORM queries, you need to surround strings with single quotes or leave the quotes out if you're passing in a number or boolean.&#x20;

Example with non-numeric value:

```javascript
bobsArticles = model("author").findAll(where="firstName='Bob'");
```

### order Argument

This maps to the `ORDER` clause of the SQL statement. If you don't specify an order at all, none will be used. (Makes sense, eh?) So in those cases, the database engine will decide in what order to return the records. Note that it's a requirement to write the SQL keywords `ASC` and `DESC` in upper case.

There is one exception to this. If you paginate the records (by passing in the `page` argument) without specifying the order, Wheels will order the results by the primary key column. This is because pagination relies on having unique records to order by.

### include Argument

This is a powerful feature that you can use if you have set up associations in your models.

If, for example, you have specified that one `Author` has many `Articles`, then you can return all authors and articles in the same call by doing this:

```javascript
bobsArticles = model("author").findAll(where="firstName='Bob'", include="Articles");
```

### maxRows Argument

This limits the number of records to return. Please note that if you call [findAll()](https://api.wheels.dev/model.findall.html) with `maxRows=1`, you will still get a `cfquery` result back and not an object. (We recommend using [findOne()](https://api.wheels.dev/model.findone.html) in this case if you want for an object to be returned.)

### page and perPage Arguments

Set these if you want to get paginated data back.

So if you wanted records 11-20, for example, you write this code:

```javascript
bobsArticles = model("author").findAll(
        where="firstName='Bob'", include="Articles", page=2, perPage=10
);
```

### cache Argument

This is the number of minutes to cache the query for. This is eventually passed on to the `cachedwithin` attribute of the `cfquery` tag.

### returnAs Argument

In the beginning of this chapter, we said that you either get a query or an object back depending on the method that you call. But you can actually specify the return type so that you get either an object, a query, or an array of objects back.

To do this, you use the `returnAs` argument. If you want an array of objects back from a [findAll()](https://api.wheels.dev/model.findall.html) call, for example, you can do this:

```javascript
users = model("user").findAll(returnAs="objects");
```

On [findOne()](https://api.wheels.dev/model.findone.html) and [findByKey()](https://api.wheels.dev/model.findbykey.html), you can set this argument to either `object` or `query`. On the [findAll()](https://api.wheels.dev/model.findall.html) method, you can set it to `objects` (note the plural) or `query`.

We recommend sticking to this convention as much as possible because of the CFML engines' slow `CreateObject()` function. Be careful when setting `returnAs` to `objects`. You won't want to create a lot of objects in your array and slow down your application unless you absolutely need to.

### useIndex Argument

If you have a specific index setup on a table that you'd like the `findAll()` call to use, you can specify a structure of arguments for each model/index you'd like to use. Only MySQL and SQLServer support index hints.

```javascript
model("author").findAll(
    include="posts",
    useIndex={
        author="idx_authors_123",
        post="idx_posts_123"
		}
);
```

### Ignoring Column(s)

For the above finder methods you are able to ignore specified column(s). For instance this can be useful when working with an existing database that has many irrelevant columns. Ignoring column(s) is achieved by adjusting the desired model's config function like below.

Ignoring one column:

```javascript
component extends="Model" {
		function config() {
			ignoredColumns(columns = ["column1"]);
		}
}
```

Ignoring multiple columns:

```javascript
component extends="Model" {
		function config() {
			ignoredColumns(columns = ["column1","column2"]);
		}
}
```
