---
title: clearErrors()
description: "Clears out all errors set on the object or only the ones set for a specific property or name."
sidebar:
  label: clearErrors()
  order: 0
---

## Signature

`clearErrors()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Clears out all errors set on the object or only the ones set for a specific property or name.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Specify a property name here if you want to clear all errors set on that property. |
| `name` | `string` | no | — | Specify an error name here if you want to clear all errors set with that error name. |

## Examples

<pre>// Clear all errors on the object as a whole
this.clearErrors();

// Clear all errors on `firstName`
this.clearErrors(&quot;firstName&quot;);</pre>
