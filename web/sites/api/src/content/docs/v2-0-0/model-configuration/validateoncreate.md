---
title: validateOnCreate()
description: "Registers method(s) that should be called to validate new objects before they are inserted."
sidebar:
  label: validateOnCreate()
  order: 0
---

## Signature

`validateOnCreate()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Registers method(s) that should be called to validate new objects before they are inserted.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

## Examples

<pre>function config(){
	// Register the `checkPhoneNumber` method below to be called to validate new objects before they are inserted.
	validateOnCreate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber(){
	// Make sure area code is `614`.
	return Left(this.phoneNumber, 3) == &quot;614&quot;;
}</pre>
