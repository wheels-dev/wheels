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
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

</div>

## Examples

<pre><code class='javascript'>// 1. Save a user object to the database (automatically does INSERT or UPDATE depending on whether the record is new)
user.save();

// 2. Use save() in a conditional to handle success and failure
if (user.save()) {
	flashInsert(notice=&quot;The user was saved successfully!&quot;);
	redirectTo(action=&quot;edit&quot;);
} else {
	flashInsert(alert=&quot;Please correct the errors below.&quot;);
	renderView(action=&quot;edit&quot;);
}

// 3. Save without running validations (useful for administrative operations or data migrations)
user.save(validate=false);

// 4. Save using cfqueryparam only on specific properties (pass a list of property names)
user.save(parameterize=&quot;firstName,lastName,email&quot;);

// 5. Save and force a database reload of the object afterward (instead of using the request-level cache)
user.save(reload=true);
</code></pre>
