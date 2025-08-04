---
description: >-
  Wheels automatically wraps your database calls in transactions to assist your
  application in maintaining data integrity. Learn how to control this
  functionality.
---

# Transactions

Database transactions are a way of grouping multiple queries together. They are useful in case the outcome of one query depends on the completion of another. For example, if you want to take money from one person's bank account, and transfer it into someone else's, you probably want to make sure the debit completes before running the credit.

You'll be pleased to know that Wheels makes using database transactions easy. In fact, the vast majority of the time, you won't need to think about using them at all because Wheels automatically runs all queries within the callback chain as a single transaction for creates, updates, and deletes.

If any of the callbacks within the chain return false, none of the queries will commit.

For example, say you want to automatically create the first post when a new author subscribes to a blog.

In your `Author` model, you would add the following code:

{% code title="Author.cfc" %}
```javascript
component extends="Model" {
  function config(){
    afterCreate("createFirstPost");
  }

  function createFirstPost(){
    var post = model("post").new(
        authorId=this.id,
        text="This is my first post!";
        post.save();
  }
}
```
{% endcode %}

In this example, if the post doesn't save (perhaps due to a validation problem), the author doesn't get created either. This helps to maintain database integrity.

### Disabling Transactions

If you want to manage transactions yourself using the `<cftransaction>` tag, you can simply add `transaction=false`to any CRUD method.

```javascript
model("author").create(name="John", transaction=false);
```

Another option is to disable transactions across your entire application using the `transactionMode` configuration:

{% code title="/templates/base/src/config/settings.cfm" %}
```javascript
set(transactionMode=false);
```
{% endcode %}

See the chapter about [Configuration and Defaults](https://wheels.dev/3.0.0/guides/working-with-wheels/configuration-and-defaults) for more details.

### Using Rollbacks

Sometimes it's useful to use a rollback to test a process without making any permanent changes to the database. To do this, add `transaction="rollback"` to any CRUD method.

```javascript
model("author").create(name="John", transaction="rollback");
```

Again, to configure your entire application to rollback _all_ transactions, you can set the `transactionMode` configuration to `rollback`.

{% code title="/templates/base/src/config/settings.cfm" %}
```javascript
set(transactionMode="rollback");
```
{% endcode %}

### Nesting Transactions with invokeWithTransaction

One issue with ColdFusion is that you cannot nest `<cftransaction>` tags. In this case, Wheels provides a workaround. If you wish to run a method within a transaction, use [invokeWithTransaction()](https://wheels.dev/api/v3.0.0/model.invokeWithTransaction.html), as below.

```javascript
invokeWithTransaction(
    method="transferFunds",
    personFrom=david,
    personTo=mary,
    amount=100
);
```
