---
title: toggle()
description: "Assigns to the property specified the opposite of the property's current boolean value."
sidebar:
  label: toggle()
  order: 0
---

## Signature

`toggle()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Assigns to the property specified the opposite of the property's current boolean value.
Throws an error if the property cannot be converted to a boolean value.
Returns this object if save called internally is <code>false</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — |  |
| `save` | `boolean` | no | `true` | Argument to decide whether save the property after it has been toggled. |

</div>

## Examples

<pre><code class='javascript'>1. Fetch a user object and toggle a boolean property
user = model("user").findByKey(58);
isSuccess = user.toggle("isActive");
// Returns true if saved successfully, false otherwise

2. Disable automatic saving
user = model("user").findByKey(58);
user.toggle(property="isActive", save=false);
// Returns the user object without saving

3. Use a dynamic helper method for convenience
user = model("user").findByKey(58);
isSuccess = user.toggleIsActive();
// Returns whether the save was successful</code></pre>
