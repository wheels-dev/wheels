---
title: clearErrors()
description: "Clears all validation or manual errors stored on a model object. You can clear all errors, or target specific errors either by property name or by a custom erro"
sidebar:
  label: clearErrors()
  order: 0
---

## Signature

`clearErrors()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Clears all validation or manual errors stored on a model object. You can clear all errors, or target specific errors either by property name or by a custom error name. This is useful when resetting an object’s state before re-validation, updating values programmatically, or handling conditional validation logic.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Specify a property name here if you want to clear all errors set on that property. |
| `name` | `string` | no | — | Specify an error name here if you want to clear all errors set with that error name. |

## Examples

<pre><code class='javascript'>1. Clear all errors on the object
// Remove all errors regardless of property
this.clearErrors();

2. Clear errors on a specific property
// Remove all errors associated with the 'firstName' property
this.clearErrors(property="firstName");

3. Clear a specific error by name
// Remove only the error named 'emailFormatError' without affecting other errors
this.clearErrors(name="emailFormatError");</code></pre>
