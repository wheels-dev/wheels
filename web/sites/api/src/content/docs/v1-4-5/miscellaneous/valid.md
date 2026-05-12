---
title: valid()
description: "Runs the validation on the object and returns true if it passes it. Wheels will run the validation process automatically whenever an object is saved to the data"
sidebar:
  label: valid()
  order: 0
---

## Signature

`valid()` — returns `any`




## Description

Runs the validation on the object and returns true if it passes it. Wheels will run the validation process automatically whenever an object is saved to the database, but sometimes it's useful to be able to run this method to see if the object is valid without saving it to the database.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |

</div>

## Examples

<pre>&lt;!--- Check if a user is valid before proceeding with execution ---&gt;
&lt;cfset user = model(&quot;user&quot;).new(params.user)&gt;
&lt;cfif user.valid()&gt;
    &lt;!--- Do something here ---&gt;
&lt;/cfif&gt;</pre>
