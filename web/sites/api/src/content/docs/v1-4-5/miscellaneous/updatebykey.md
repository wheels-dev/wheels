---
title: updateByKey()
description: "Finds the object with the supplied key and saves it (if validation permits it) with the supplied properties and/or named arguments. Property names and values ca"
sidebar:
  label: updateByKey()
  order: 0
---

## Signature

`updateByKey()` — returns `any`




## Description

Finds the object with the supplied key and saves it (if validation permits it) with the supplied properties and/or named arguments. Property names and values can be passed in either using named arguments or as a struct to the properties argument. Returns true if the object was found and updated successfully, false otherwise.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `properties` | `struct` | yes | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `validate` | `boolean` | yes | `true` | Set to false to skip validations for this operation. |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |

</div>

## Examples

<pre>updateByKey(key [, properties, reload, validate, transaction, callbacks, includeSoftDeletes ]) &lt;!--- Updates the object with `33` as the primary key value with values passed in through the URL/form ---&gt;
&lt;cfset result = model(&quot;post&quot;).updateByKey(33, params.post)&gt;

&lt;!--- Updates the object with `33` as the primary key using named arguments ---&gt;
&lt;cfset result = model(&quot;post&quot;).updateByKey(key=33, title=&quot;New version of Wheels just released&quot;, published=1)&gt;</pre>
