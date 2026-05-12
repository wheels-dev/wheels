---
title: setPrimaryKeys()
description: "Alias for <code>setPrimaryKey()</code>."
sidebar:
  label: setPrimaryKeys()
  order: 0
---

## Signature

`setPrimaryKeys()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Alias for <code>setPrimaryKey()</code>.
Use this for better readability when you're setting multiple properties as the primary key.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Property (or list of properties) to set as the primary key. |

</div>

## Examples

<pre><code class='javascript'>// In `models/Subscription.cfc`, define the primary key as composite of the columns `customerId` and `publicationId`.
function config(){
	setPrimaryKeys(&quot;customerId,publicationId&quot;);
}</code></pre>
