---
title: validatesPresenceOf()
description: "Validates that the specified property exists and that its value is not blank."
sidebar:
  label: validatesPresenceOf()
  order: 0
---

## Signature

`validatesPresenceOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the specified property exists and that its value is not blank.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] can't be empty` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>// Make sure that the user data can not be saved to the database without the `emailAddress` property. (It must exist and not be an empty string)
validatesPresenceOf(&quot;emailAddress&quot;);</code></pre>
