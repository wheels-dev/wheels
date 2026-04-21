---
title: new()
description: "Creates a new object based on supplied <code>properties</code> and returns it."
sidebar:
  label: new()
  order: 0
---

## Signature

`new()` — returns `any`

**Available in:** `model`
**Category:** Create Functions

## Description

Creates a new object based on supplied <code>properties</code> and returns it.
The object is not saved to the database, it only exists in memory.
Property names and values can be passed in either using named arguments or as a struct to the <code>properties</code> argument.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

</div>

## Examples

<pre>// Create a new author in memory (not saved to the database)
newAuthor = model(&quot;author&quot;).new();

// Create a new author based on properties in a struct
newAuthor = model(&quot;author&quot;).new(params.authorStruct);

// Create a new author by passing in named arguments
newAuthor = model(&quot;author&quot;).new(firstName=&quot;John&quot;, lastName=&quot;Doe&quot;);

// If you have a `hasOne` or `hasMany` association setup from `customer` to `order`, you can do a scoped call. (The `newOrder` method below will call `model(&quot;order&quot;).new(customerId=aCustomer.id)` internally.)
aCustomer = model(&quot;customer&quot;).findByKey(params.customerId);
anOrder = aCustomer.newOrder(shipping=params.shipping);</pre>
