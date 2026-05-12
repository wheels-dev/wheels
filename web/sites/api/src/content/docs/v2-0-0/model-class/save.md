---
title: save()
description: "Saves the object if it passes validation and callbacks."
sidebar:
  label: save()
  order: 0
---

## Signature

`save()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Saves the object if it passes validation and callbacks.
Returns <code>true</code> if the object was saved successfully to the database, <code>false</code> if not.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

</div>

## Examples

<pre>// Save the user object to the database (will automatically do an `INSERT` or `UPDATE` statement depending on if the record is new or already exists
user.save();

// Save the user object directly in an if statement without using `cfqueryparam` and take appropriate action based on the result
if(user.save(parameterize=false)){
	flashInsert(notice=&quot;The user was saved!&quot;);
	redirectTo(action=&quot;edit&quot;);
} else {
	flashInsert(alert=&quot;Error, please correct!&quot;);
	renderView(action=&quot;edit&quot;);
}</pre>
