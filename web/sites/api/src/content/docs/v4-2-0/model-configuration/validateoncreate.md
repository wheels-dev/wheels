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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a custom method to validate new objects before insert
function config() {
	// `checkPhoneNumber` will only be called when creating a new record.
	validateOnCreate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber() {
	// Make sure area code is `614`.
	return Left(this.phoneNumber, 3) == &quot;614&quot;;
}

// 2. Register multiple validation methods at once
function config() {
	validateOnCreate(&quot;checkPhoneNumber,checkReferralCode&quot;);
}

function checkPhoneNumber() {
	return Left(this.phoneNumber, 3) == &quot;614&quot;;
}

function checkReferralCode() {
	if (Len(this.referralCode) &amp;&amp; !isValidReferral(this.referralCode)) {
		addError(property=&quot;referralCode&quot;, message=&quot;Invalid referral code.&quot;);
	}
}

// 3. Only run the validation when a condition is met
function config() {
	// Only validate the phone number on create when the user is in the US.
	validateOnCreate(methods=&quot;checkPhoneNumber&quot;, condition=&quot;this.country eq 'US'&quot;);
}

function checkPhoneNumber() {
	return IsNumeric(this.phoneNumber);
}
</code></pre>
