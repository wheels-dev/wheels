---
title: hasMany()
description: "Sets up a <code>hasMany</code> association between this model and the specified one."
sidebar:
  label: hasMany()
  order: 0
---

## Signature

`hasMany()` — returns `void`

**Available in:** `model`
**Category:** Association Functions

## Description

Sets up a <code>hasMany</code> association between this model and the specified one.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example). |
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow CFWheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow CFWheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow CFWheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `outer` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |
| `dependent` | `string` | no | `false` | Defines how to handle dependent model objects when you delete an object from this model. `delete` / `deleteAll` deletes the record(s) (`deleteAll` bypasses object instantiation). `remove` / `removeAll` sets the forein key field(s) to `NULL` (`removeAll` bypasses object instantiation). |
| `shortcut` | `string` | no | — | Set this argument to create an additional dynamic method that gets the object(s) from the other side of a many-to-many association. |
| `through` | `string` | no | `[runtime expression]` | Set this argument if you need to override CFWheels conventions when using the `shortcut` argument. Accepts a list of two association names representing the chain from the opposite side of the many-to-many relationship to this model. |

## Examples

<pre>// Specify that instances of this model has many comments (the table for the associated model, not the current, should have the foreign key set on it).
hasMany(&quot;comments&quot;);

// Specify that this model (let's call it `reader` in this case) has many subscriptions and setup a shortcut to the `publication` model (useful when dealing with many-to-many relationships).
hasMany(name=&quot;subscriptions&quot;, shortcut=&quot;publications&quot;);

// Automatically delete all associated `comments` whenever this object is deleted.
hasMany(name=&quot;comments&quot;, dependent=&quot;deleteAll&quot;);

// When not following CFWheels naming conventions for associations, it can get complex to define how a `shortcut` works.
// In this example, we are naming our `shortcut` differently than the actual model's name.

// In the models/Customer.cfc `config()` method.
hasMany(name=&quot;subscriptions&quot;, shortcut=&quot;magazines&quot;, through=&quot;publication,subscriptions&quot;);

// In the models/Subscription.cfc `config()` method.
belongsTo(&quot;customer&quot;);
belongsTo(&quot;publication&quot;);

// In the models/Publication `config()` method.
hasMany(&quot;subscriptions&quot;);
</pre>
