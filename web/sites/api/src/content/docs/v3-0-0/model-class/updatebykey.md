---
title: updateByKey()
description: "Finds the object with the supplied <code>key</code> and saves it (if validation permits it) with the supplied <code>properties</code> and / or named arguments."
sidebar:
  label: updateByKey()
  order: 0
---

## Signature

`updateByKey()` — returns `boolean`

**Available in:** `model`
**Category:** Update Functions

## Description

Finds the object with the supplied <code>key</code> and saves it (if validation permits it) with the supplied <code>properties</code> and / or named arguments.
Property names and values can be passed in either using named arguments or as a struct to the <code>properties</code> argument.
Returns <code>true</code> if the object was found and updated successfully, <code>false</code> otherwise.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `any` | yes | — | Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value. |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |

## Examples

<pre><code class='javascript'>1. Update a record by key using a struct of properties
result = model(&quot;post&quot;).updateByKey(33, params.post);
// Returns true if the update was successful

2. Update a record by key using named arguments
result = model(&quot;post&quot;).updateByKey(
 key=33,
 title=&quot;New version of Wheels just released&quot;,
 published=1
)

3. Include soft-deleted records in the update
result = model(&quot;user&quot;).updateByKey(
 key=42,
 properties={isActive=true},
 includeSoftDeletes=true
)

4. Disable validation and callbacks
result = model(&quot;post&quot;).updateByKey(
 key=33,
 properties={title=&quot;Force Update&quot;},
 validate=false,
 callbacks=false
)
</code></pre>
