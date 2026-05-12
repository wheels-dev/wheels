---
title: errorsOnBase()
description: "Returns an array of all errors associated with the object as a whole (not related to any specific property)."
sidebar:
  label: errorsOnBase()
  order: 0
---

## Signature

`errorsOnBase()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns an array of all errors associated with the object as a whole (not related to any specific property).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Specify an error name here to only return errors for that error name. |

</div>

## Examples

<pre><code class='javascript'>// Get all general type errors for the user object
errors = user.errorsOnBase();</code></pre>
