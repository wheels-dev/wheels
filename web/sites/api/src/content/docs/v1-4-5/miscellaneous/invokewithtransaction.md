---
title: invokeWithTransaction()
description: "Runs the specified method within a single database transaction."
sidebar:
  label: invokeWithTransaction()
  order: 0
---

## Signature

`invokeWithTransaction()` — returns `any`




## Description

Runs the specified method within a single database transaction.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | yes | — | Model method to run. |
| `transaction` | `string` | yes | `commit` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `isolation` | `string` | yes | `read_committed` | Isolation level to be passed through to the cftransaction tag. See your CFML engine's documentation for more details about cftransaction's isolation attribute. |

</div>

## Examples

<pre>invokeWithTransaction(method [, transaction, isolation ]) &lt;!--- This is the method to be run inside a transaction ---&gt;
&lt;cffunction name=&quot;transferFunds&quot; returntype=&quot;boolean&quot; output=&quot;false&quot;&gt;
    &lt;cfargument name=&quot;personFrom&quot;&gt;
    &lt;cfargument name=&quot;personTo&quot;&gt;
    &lt;cfargument name=&quot;amount&quot;&gt;
    &lt;cfif arguments.personFrom.withdraw(arguments.amount) and arguments.personTo.deposit(arguments.amount)&gt;
        &lt;cfreturn true&gt;
    &lt;cfelse&gt;
        &lt;cfreturn false&gt;
    &lt;/cfif&gt;
&lt;/cffunction&gt;

&lt;cfset david = model(&quot;Person&quot;).findOneByName(&quot;David&quot;)&gt;
&lt;cfset mary = model(&quot;Person&quot;).findOneByName(&quot;Mary&quot;)&gt;
&lt;cfset invokeWithTransaction(method=&quot;transferFunds&quot;, personFrom=david, personTo=mary, amount=100)&gt;</pre>
