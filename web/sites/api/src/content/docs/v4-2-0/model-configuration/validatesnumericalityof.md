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

<pre><code class='javascript'>// 1. Validate that the `age` property is a number
validatesNumericalityOf(property=&quot;age&quot;);

// 2. Validate that the `score` property is a whole number (no decimals), allowing blank so that
// records can be saved without a score (resulting in a NULL in the database)
validatesNumericalityOf(property=&quot;score&quot;, onlyInteger=true, allowBlank=true, message=&quot;Please enter a whole number for score.&quot;);

// 3. Validate that a `price` value is greater than zero and no more than 10000
validatesNumericalityOf(property=&quot;price&quot;, greaterThan=0, lessThanOrEqualTo=10000);

// 4. Validate that `quantity` is at least 1, is an integer, and only on create
validatesNumericalityOf(property=&quot;quantity&quot;, onlyInteger=true, greaterThanOrEqualTo=1, when=&quot;onCreate&quot;);

// 5. Validate that `rating` must be exactly 5 only when a condition is met
validatesNumericalityOf(property=&quot;rating&quot;, equalTo=5, condition=&quot;this.isPerfect()&quot;);

// 6. Validate that `luckyNumber` is an odd number
validatesNumericalityOf(property=&quot;luckyNumber&quot;, odd=true, message=&quot;[property] must be an odd number.&quot;);
</code></pre>
