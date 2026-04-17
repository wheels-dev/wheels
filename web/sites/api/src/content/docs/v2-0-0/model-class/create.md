---
title: create()
description: "Creates a new object, saves it to the database (if the validation permits it), and returns it."
sidebar:
  label: create()
  order: 0
---

## Signature

`create()` — returns `any`

**Available in:** `model`
**Category:** Create Functions

## Description

Creates a new object, saves it to the database (if the validation permits it), and returns it.
If the validation fails, the unsaved object (with errors added to it) is still returned.
Property names and values can be passed in either using named arguments or as a struct to the <code>properties</code> argument.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

## Examples

<pre>// Create a new author and save it to the database
newAuthor = model(&quot;author&quot;).create(params.author);

// Same as above using named arguments
newAuthor = model(&quot;author&quot;).create(firstName=&quot;John&quot;, lastName=&quot;Doe&quot;);

// Same as above using both named arguments and a struct
newAuthor = model(&quot;author&quot;).create(active=1, properties=params.author);

// If you have a `hasOne` or `hasMany` association setup from `customer` to `order`, you can do a scoped call. (The `createOrder` method below will call `model(&quot;order&quot;).create(customerId=aCustomer.id, shipping=params.shipping)` internally.)
aCustomer = model(&quot;customer&quot;).findByKey(params.customerId);
anOrder = aCustomer.createOrder(shipping=params.shipping);</pre>
