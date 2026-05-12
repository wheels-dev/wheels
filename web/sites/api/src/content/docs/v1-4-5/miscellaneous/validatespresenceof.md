---
title: validatesPresenceOf()
description: "Validates that the specified property exists and that its value is not blank."
sidebar:
  label: validatesPresenceOf()
  order: 0
---

## Signature

`validatesPresenceOf()` — returns `any`




## Description

Validates that the specified property exists and that its value is not blank.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `message` | `string` | yes | `[property] can't be empty` | See documentation for validatesConfirmationOf. |
| `when` | `string` | yes | `onSave` | See documentation for validatesConfirmationOf. |
| `condition` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `unless` | `string` | yes | — | See documentation for validatesConfirmationOf. |

</div>

## Examples

<pre>// Make sure that the user data can not be saved to the database without the `emailAddress` property. (It must exist and not be an empty string)
validatesPresenceOf(&quot;emailAddress&quot;);</pre>
