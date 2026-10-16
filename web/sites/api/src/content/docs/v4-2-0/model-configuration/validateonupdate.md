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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single custom validation method to run only on updates
component extends=&quot;Model&quot; {
	function config() {
		validateOnUpdate(&quot;checkPhoneNumber&quot;);
	}

	private boolean function checkPhoneNumber() {
		// Make sure area code is 614
		return Left(this.phoneNumber, 3) == &quot;614&quot;;
	}
}

// 2. Register multiple custom validation methods for updates
component extends=&quot;Model&quot; {
	function config() {
		validateOnUpdate(methods=&quot;checkStatus,checkExpiry&quot;);
	}

	private boolean function checkStatus() {
		return ListFindNoCase(&quot;active,pending,suspended&quot;, this.status);
	}

	private boolean function checkExpiry() {
		return this.expiresAt &gt; Now();
	}
}

// 3. Only validate when a condition is met (run only for premium accounts)
component extends=&quot;Model&quot; {
	function config() {
		validateOnUpdate(methods=&quot;checkBillingAddress&quot;, condition=&quot;this.accountType eq 'premium'&quot;);
	}

	private boolean function checkBillingAddress() {
		return Len(Trim(this.billingAddress)) GT 0;
	}
}
</code></pre>
