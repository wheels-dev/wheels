---
title: validatesNumericalityOf()
description: "Validates that the value of the specified property is numeric."
sidebar:
  label: validatesNumericalityOf()
  order: 0
---

## Signature

`validatesNumericalityOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property is numeric.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] is not a number` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `onlyInteger` | `boolean` | no | `false` | Specifies whether the property value must be an integer. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |
| `odd` | `boolean` | no | — |  |
| `even` | `boolean` | no | — |  |
| `greaterThan` | `numeric` | no | — | Specifies whether or not the value must be greater than the supplied value. |
| `greaterThanOrEqualTo` | `numeric` | no | — | Specifies whether or not the value must be greater than or equal the supplied value. |
| `equalTo` | `numeric` | no | — | Specifies whether or not the value must be equal to the supplied value. |
| `lessThan` | `numeric` | no | — | Specifies whether or not the value must be less than the supplied value. |
| `lessThanOrEqualTo` | `numeric` | no | — | Specifies whether or not the value must be less than or equal the supplied value. |

</div>

## Examples

<pre><code class='javascript'>// Make sure that the score is a number with no decimals but only when a score is supplied. (Tetting `allowBlank` to `true` means that objects are allowed to be saved without scores, typically resulting in `NULL` values being inserted in the database table)
validatesNumericalityOf(property=&quot;score&quot;, onlyInteger=true, allowBlank=true, message=&quot;Please enter a correct score.&quot;);</code></pre>
