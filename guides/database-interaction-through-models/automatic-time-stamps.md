---
description: Let Wheels handle time stamping of records.
---

# Automatic Time Stamps

When working with database tables, it is very common to have a column that holds the time that the record was added or last modified. If you have an e-commerce website with an orders table, you want to store the date and time the order was made; if you run a blog, you want to know when someone left a comment; and so on.

As with anything that is a common task performed by many developers, it makes a good candidate for abstracting to the framework level. So that's what we did.

### Columns Used for Timestamps

If you have either of the following columns in your database table, Wheels will see them and treat them a little differently than others.

**createdat**

Wheels will use a `createdat` column automatically to store the current date and time when an `INSERT`operation is made (which could happen through a [save()](https://api.wheels.dev/model.save.html) or [create()](https://api.wheels.dev/model.create.html) operation, for example).

**updatedat**

If Wheels sees an `updatedat` column, it will use it to store the current date and time automatically when an `UPDATE` operation is made (which could happen through a [save()](https://api.wheels.dev/model.save.html) or [update()](https://api.wheels.dev/model.update.html) operation, for example).

### Data Type of Columns

If you add any of these columns to your table, make sure they can accept date/time values (like `datetime` or `timestamp`, for example) and that they can be set to `null`.

### Time Zones

Time stamping is done in UTC (Coordinated Universal Time) by default but if you want to use your local time instead all you have to do is change the global setting for it like this:

`set(timeStampMode="local");`
