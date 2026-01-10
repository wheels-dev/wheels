---
description: An easy way to keep deleted data in your database.
---

# Soft Delete

"Soft delete" in database lingo means that you set a flag on an existing table which indicates that a record has been deleted, instead of actually deleting the record.

### How to Use Soft Deletion

If you create a new date column (the column type will depend on your database vendor, but usually you want to use `date, datetime`, or `timestamp`) on a table and name it `deletedAt`, Wheels will automagically start using it to record soft deletes.

Without the soft delete in place, a `delete()` call on an object will delete the record from the table using a `DELETE` statement. With the soft delete in place, an `UPDATE` statement is sent instead (that sets the `deletedAt` field to the current time).

Of course, all other Wheels functions are smart enough to respect this. So if you use a `findAll()` function, for example, it will not return any record that has a value set in the `deletedAt` field.

What this all means is that you're given a convenient way to keep deleted data in your database forever, while having your application function as if the data is not there.

### Getting data including Soft Deletes

Occasionally you might want to include data which has been flagged for deletion. You can do this easily by adding `includeSoftDeletes=true` to any `findAll` type call.

Obviously, if you have any manual queries in your application, you'll need to remember to add `deletedAt IS NULL` to the `WHERE` part of your SQL statements instead.
