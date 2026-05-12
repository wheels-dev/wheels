---
title: create()
description: "Creates a new object, saves it to the database (if the validation permits it), and returns it. If the validation fails, the unsaved object (with errors added to"
sidebar:
  label: create()
  order: 0
---

## Signature

`create()` — returns `any`




## Description

Creates a new object, saves it to the database (if the validation permits it), and returns it. If the validation fails, the unsaved object (with errors added to it) is still returned. Property names and values can be passed in either using named arguments or as a struct to the properties argument.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | yes | — | See documentation for new. |
| `parameterize` | `any` | yes | `true` | See documentation for findAll. |
| `reload` | `boolean` | yes | `false` | See documentation for save. |
| `validate` | `boolean` | yes | `true` | See documentation for save. |
| `transaction` | `string` | yes | — | See documentation for save. |
| `callbacks` | `boolean` | yes | `true` | See documentation for save. |

</div>

## Examples

<pre>&lt;!--- Create a new author and save it to the database ---&gt;
&lt;cfset newAuthor = model(&quot;author&quot;).create(params.author)&gt;

&lt;!--- Same as above using named arguments ---&gt;
&lt;cfset newAuthor = model(&quot;author&quot;).create(firstName=&quot;John&quot;, lastName=&quot;Doe&quot;)&gt;

&lt;!--- Same as above using both named arguments and a struct ---&gt;
&lt;cfset newAuthor = model(&quot;author&quot;).create(active=1, properties=params.author)&gt;

&lt;!--- If you have a `hasOne` or `hasMany` association setup from `customer` to `order`, you can do a scoped call. (The `createOrder` method below will call `model(&quot;order&quot;).create(customerId=aCustomer.id, shipping=params.shipping)` internally.) ---&gt;
&lt;cfset aCustomer = model(&quot;customer&quot;).findByKey(params.customerId)&gt;
&lt;cfset anOrder = aCustomer.createOrder(shipping=params.shipping)&gt;</pre>
