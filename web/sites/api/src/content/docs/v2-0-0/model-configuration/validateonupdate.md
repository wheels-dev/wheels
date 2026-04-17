---
title: validateOnUpdate()
description: "Registers method(s) that should be called to validate existing objects before they are updated."
sidebar:
  label: validateOnUpdate()
  order: 0
---

## Signature

`validateOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Registers method(s) that should be called to validate existing objects before they are updated.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

## Examples

<pre>function config(){
	// Register the `check` method below to be called to validate existing objects before they are updated.
	validateOnUpdate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber(){
	// Make sure area code is `614`
	return Left(this.phoneNumber, 3) == &quot;614&quot;;
}</pre>
