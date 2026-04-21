---
title: hasOne()
description: "Sets up a <code>hasOne</code> association between this model and the specified one."
sidebar:
  label: hasOne()
  order: 0
---

## Signature

`hasOne()` — returns `void`

**Available in:** `model`
**Category:** Association Functions

## Description

Sets up a <code>hasOne</code> association between this model and the specified one.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example). |
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow CFWheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow CFWheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow CFWheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `outer` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |
| `dependent` | `string` | no | `false` | Defines how to handle dependent model objects when you delete an object from this model. `delete` / `deleteAll` deletes the record(s) (`deleteAll` bypasses object instantiation). `remove` / `removeAll` sets the forein key field(s) to `NULL` (`removeAll` bypasses object instantiation). |

</div>

## Examples

<pre>// Specify that instances of this model has one profile. (The table for the associated model, not the current, should have the foreign key set on it.)
hasOne(&quot;profile&quot;);

// Same as above but setting the `joinType` to `inner`, which basically means this model should always have a record in the `profiles` table.
hasOne(name=&quot;profile&quot;, joinType=&quot;inner&quot;);

// Automatically delete the associated `profile` whenever this object is deleted.
hasMany(name=&quot;comments&quot;, dependent=&quot;delete&quot;);
</pre>
