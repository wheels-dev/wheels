---
description: Make your model calls more readable by using dynamic finders.
---

# Dynamic Finders

Since the introduction of `onMissingMethod()` in CFML, we have been able to port over the concept of _dynamic finders_from Rails to Wheels.

The concept is simple. Instead of using arguments to tell Wheels what you want to do, you can use a dynamically-named method.

For example, the following code:

```javascript
me = model("user").findOne(where="email='me@myself.com'");
```

Can also be written as:

```javascript
me = model("user").findOneByEmail("me@myself.com");
```

Through the power of `onMissingMethod()`, Wheels will parse the method name and figure out that the value supplied is supposed to be matched against the `email` column.

### Dynamic Finders Involving More than One Column

You can take this one step further by using code such as:

```javascript
me = model("user").findOneByUserNameAndPassword("bob,pass");
```

In this case, Wheels will split the function name on the And part and determine that you want to find the record where the username column is "bob" and the password column is "pass".

When you are passing in two values, make special note of the fact that they should be passed in as a list to one argument and not as two separate arguments.

### Works with findAll() too

In the examples above, we've used the [findOne()](https://wheels.dev/api/v3.0.0/model.findone.html) method, but you can use the same approach on a [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html) method as well.

### Passing in Other Finder Parameters

In the background, these dynamically-named methods just pass along execution to [findOne()](https://wheels.dev/api/v3.0.0/model.findone.html) or [findAll()](https://wheels.dev/api/v3.0.0/model.findall.html). This means that you can also pass in any arguments that are accepted by those two methods.

The below code, for example, is perfectly valid:

```javascript
users = model("user").findAllByState(value="NY", order="name", page=3);
```

When passing in multiple arguments like above, you have to start naming them instead of relying on the order of the arguments though. When doing so, you need to name the argument `value` if you're passing in just one value and `values` if you're passing in multiple values in a list. In other words, you need to name it `values` when calling an `And`type dynamic finder.

```javascript
users = model("user").findAllByCityAndState(
        values="Buffalo,NY", order="name", page=3
);
```

### Avoid the Word "And" in Database Column Names

Keep in mind that this dynamic method calling will break down completely if you ever name a column `firstandlastname` or something similar because Wheels will then split the method name incorrectly. So avoid using "And" in the column name if you plan on taking advantage of dynamically-named finder methods.
