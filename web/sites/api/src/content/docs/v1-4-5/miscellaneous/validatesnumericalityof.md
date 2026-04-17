---
title: validatesNumericalityOf()
description: "Validates that the value of the specified property is numeric."
sidebar:
  label: validatesNumericalityOf()
  order: 0
---

## Signature

`validatesNumericalityOf()` — returns `any`




## Description

Validates that the value of the specified property is numeric.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `message` | `string` | yes | `[property] is not a number` | See documentation for validatesConfirmationOf. |
| `when` | `string` | yes | `onSave` | See documentation for validatesConfirmationOf. |
| `allowBlank` | `boolean` | yes | `false` | See documentation for validatesExclusionOf. |
| `onlyInteger` | `boolean` | yes | `false` | Specifies whether the property value must be an integer. |
| `condition` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `unless` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `odd` | `boolean` | yes | — | Specifies whether or not the value must be an odd number. |
| `even` | `boolean` | yes | — | Specifies whether or not the value must be an even number. |
| `greaterThan` | `numeric` | yes | — | Specifies whether or not the value must be greater than the supplied value. |
| `greaterThanOrEqualTo` | `numeric` | yes | — | Specifies whether or not the value must be greater than or equal the supplied value. |
| `equalTo` | `numeric` | yes | — | Specifies whether or not the value must be equal to the supplied value. |
| `lessThan` | `numeric` | yes | — | Specifies whether or not the value must be less than the supplied value. |
| `lessThanOrEqualTo` | `numeric` | yes | — | Specifies whether or not the value must be less than or equal the supplied value. |

## Examples

<pre>// Make sure that the score is a number with no decimals but only when a score is supplied. (Tetting `allowBlank` to `true` means that objects are allowed to be saved without scores, typically resulting in `NULL` values being inserted in the database table)
validatesNumericalityOf(property=&quot;score&quot;, onlyInteger=true, allowBlank=true, message=&quot;Please enter a correct score.&quot;);</pre>
