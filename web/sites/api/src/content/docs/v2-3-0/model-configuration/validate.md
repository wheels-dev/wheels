---
title: validate()
description: "Registers method(s) that should be called to validate objects before they are saved."
sidebar:
  label: validate()
  order: 0
---

## Signature

`validate()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Registers method(s) that should be called to validate objects before they are saved.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |

## Examples

<pre><code class='javascript'>function config() {
	// Register the `checkPhoneNumber` method below to be called to validate objects before they are saved.
	validate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber() {
	// Make sure area code is `614`.
	return Left(this.phoneNumber, 3) == &quot;614&quot;;
}</code></pre>
