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
| `allowExplicitTimestamps` | `boolean` | no | `false` | Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties |

</div>

## Examples

<pre><code class='javascript'>// 1. Create a new author in memory (not saved to the database)
newAuthor = model(&quot;author&quot;).new();

// 2. Create a new author by passing in a struct of properties
newAuthor = model(&quot;author&quot;).new(params.authorStruct);

// 3. Create a new author by passing in named arguments
newAuthor = model(&quot;author&quot;).new(firstName=&quot;John&quot;, lastName=&quot;Doe&quot;);

// 4. Create a new object without running callbacks
newAuthor = model(&quot;author&quot;).new(firstName=&quot;Jane&quot;, callbacks=false);

// 5. Create a new object and allow explicit assignment of timestamp properties
newAuthor = model(&quot;author&quot;).new(firstName=&quot;Bob&quot;, createdAt=&quot;2024-01-01&quot;, allowExplicitTimestamps=true);

// 6. Scoped call via a `hasMany` association (calls `model(&quot;order&quot;).new(customerId=aCustomer.id)` internally)
aCustomer = model(&quot;customer&quot;).findByKey(params.customerId);
anOrder = aCustomer.newOrder(shipping=params.shipping);
</code></pre>
