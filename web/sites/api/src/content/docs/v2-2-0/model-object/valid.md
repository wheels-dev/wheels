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
CFWheels will run the validation process automatically whenever an object is saved to the database, but sometimes it's useful to be able to run this method to see if the object is valid without saving it to the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

</div>

## Examples

<pre><code class='javascript'>// Check if a user is valid before proceeding with execution
user = model(&quot;user&quot;).new(params.user);

if user.valid(){
    // Do something here
}</code></pre>
