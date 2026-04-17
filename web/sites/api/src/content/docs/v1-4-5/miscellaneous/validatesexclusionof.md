---
title: validatesExclusionOf()
description: "Validates that the value of the specified property does not exist in the supplied list."
sidebar:
  label: validatesExclusionOf()
  order: 0
---

## Signature

`validatesExclusionOf()` — returns `any`




## Description

Validates that the value of the specified property does not exist in the supplied list.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `list` | `string` | yes | — | Single value or list of values that should not be allowed. |
| `message` | `string` | yes | `[property] is reserved` | See documentation for validatesConfirmationOf. |
| `when` | `string` | yes | `onSave` | See documentation for validatesConfirmationOf. |
| `allowBlank` | `boolean` | yes | `false` | If set to true, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the validatesPresenceOf test, thus avoiding duplicate error messages if it doesn't. |
| `condition` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `unless` | `string` | yes | — | See documentation for validatesConfirmationOf. |

## Examples

<pre>// Do not allow &quot;PHP&quot; or &quot;Fortran&quot; to be saved to the database as a cool language
validatesExclusionOf(property=&quot;coolLanguage&quot;, list=&quot;php,fortran&quot;, message=&quot;Haha, you can not be serious. Try again, please.&quot;);</pre>
