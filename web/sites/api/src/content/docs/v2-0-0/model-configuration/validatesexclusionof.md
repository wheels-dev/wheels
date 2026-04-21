---
title: validatesExclusionOf()
description: "Validates that the value of the specified property does not exist in the supplied list."
sidebar:
  label: validatesExclusionOf()
  order: 0
---

## Signature

`validatesExclusionOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property does not exist in the supplied list.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `list` | `string` | yes | — | Single value or list of values that should not be allowed. |
| `message` | `string` | no | `[property] is reserved` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre>// Do not allow &quot;PHP&quot; or &quot;Fortran&quot; to be saved to the database as a cool language
validatesExclusionOf(property=&quot;coolLanguage&quot;, list=&quot;php,fortran&quot;, message=&quot;Haha, you can not be serious. Try again, please.&quot;);</pre>
