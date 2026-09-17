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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a custom validation method to run on every save
function config() {
	// `checkPhoneNumber` will be called whenever an object is created or updated.
	validate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber() {
	// Make sure the area code is `614`.
	return Left(this.phoneNumber, 3) == &quot;614&quot;;
}

// 2. Register multiple custom validation methods at once
function config() {
	validate(methods=&quot;checkPhoneNumber,checkEmailDomain&quot;);
}

// 3. Limit validation to create or update only
function config() {
	// Only run `checkTrialExpiry` when updating an existing record.
	validate(methods=&quot;checkTrialExpiry&quot;, when=&quot;onUpdate&quot;);
}

// 4. Run a custom validation only when a condition is met
function config() {
	// `checkBillingAddress` is skipped when the order is free.
	validate(methods=&quot;checkBillingAddress&quot;, condition=&quot;this.totalAmount gt 0&quot;);
}

// 5. Skip a custom validation when an `unless` expression is true
function config() {
	// `checkCreditCard` is skipped for admin users.
	validate(methods=&quot;checkCreditCard&quot;, unless=&quot;this.isAdmin&quot;);
}
</code></pre>
