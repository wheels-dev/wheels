---
title: valid()
description: "Runs the validation on the object and returns <code>true</code> if it passes it."
sidebar:
  label: valid()
  order: 0
---

## Signature

`valid()` — returns `boolean`

**Available in:** `model`
**Category:** Error Functions

## Description

Runs the validation on the object and returns <code>true</code> if it passes it.
Wheels will run the validation process automatically whenever an object is saved to the database, but sometimes it's useful to be able to run this method to see if the object is valid without saving it to the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `validateAssociations` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Check if a new user object passes validation before proceeding
user = model(&quot;User&quot;).new(params.user);

if (user.valid()) {
    // object passed all validations, safe to proceed
    redirectTo(action=&quot;dashboard&quot;);
} else {
    renderView(action=&quot;new&quot;);
}

// 2. Validate without running before/after validation callbacks
user = model(&quot;User&quot;).new(params.user);

if (user.valid(callbacks=false)) {
    user.save(callbacks=false);
}

// 3. Validate the object and any associated (nested) objects together
order = model(&quot;Order&quot;).new(params.order);

if (order.valid(validateAssociations=true)) {
    order.save();
} else {
    // errors may include issues from associated line items
    writeOutput(order.errorsAsHTML());
}
</code></pre>
