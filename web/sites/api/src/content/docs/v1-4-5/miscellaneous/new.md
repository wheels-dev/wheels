---
title: new()
description: "Creates a new object based on supplied properties and returns it. The object is not saved to the database; it only exists in memory. Property names and values c"
sidebar:
  label: new()
  order: 0
---

## Signature

`new()` — returns `any`




## Description

Creates a new object based on supplied properties and returns it. The object is not saved to the database; it only exists in memory. Property names and values can be passed in either using named arguments or as a struct to the properties argument.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | yes | — | The properties you want to set on the object (can also be passed in as named arguments). |
| `callbacks` | `boolean` | yes | `true` | See documentation for save. |

## Examples

<pre>&lt;!--- Create a new author in memory (not saved to the database) ---&gt;
&lt;cfset newAuthor = model(&quot;author&quot;).new()&gt;

&lt;!--- Create a new author based on properties in a struct ---&gt;
&lt;cfset newAuthor = model(&quot;author&quot;).new(params.authorStruct)&gt;

&lt;!--- Create a new author by passing in named arguments ---&gt;
&lt;cfset newAuthor = model(&quot;author&quot;).new(firstName=&quot;John&quot;, lastName=&quot;Doe&quot;)&gt;

&lt;!--- If you have a `hasOne` or `hasMany` association setup from `customer` to `order`, you can do a scoped call. (The `newOrder` method below will call `model(&quot;order&quot;).new(customerId=aCustomer.id)` internally.) ---&gt;
&lt;cfset aCustomer = model(&quot;customer&quot;).findByKey(params.customerId)&gt;
&lt;cfset anOrder = aCustomer.newOrder(shipping=params.shipping)&gt;</pre>
