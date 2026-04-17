---
title: invokeWithTransaction()
description: "Runs a specified model method inside a single database transaction. This ensures that all database operations within the method are treated as a single atomic u"
sidebar:
  label: invokeWithTransaction()
  order: 0
---

## Signature

`invokeWithTransaction()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Runs a specified model method inside a single database transaction. This ensures that all database operations within the method are treated as a single atomic unit: either all succeed or all fail.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | yes | — | Model method to run. |
| `transaction` | `string` | no | `commit` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `isolation` | `string` | no | `read_committed` | Isolation level to be passed through to the cftransaction tag. See your CFML engine's documentation for more details about cftransaction's isolation attribute. |

## Examples

<pre><code class='javascript'>1. This is the method to be run inside a transaction.
public boolean function transferFunds(required any personFrom, required any personTo, required numeric amount) {
	if (arguments.personFrom.withdraw(arguments.amount) &amp;&amp; arguments.personTo.deposit(arguments.amount)) {
		return true;
	} else {
		return false;
	}
}

local.david = model(&quot;Person&quot;).findOneByName(&quot;David&quot;);
local.mary = model(&quot;Person&quot;).findOneByName(&quot;Mary&quot;);
invokeWithTransaction(method=&quot;transferFunds&quot;, personFrom=local.david, personTo=local.mary, amount=100);
</code></pre>
