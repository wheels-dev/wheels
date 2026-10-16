---
title: afterFind()
description: "Registers method(s) that should be called after an existing object has been initialized (which is usually done with the <code>findByKey</code> or <code>findOne<"
sidebar:
  label: afterFind()
  order: 0
---

## Signature

`afterFind()` — returns `void`

**Available in:** `model`
**Category:** Callback Functions

## Description

Registers method(s) that should be called after an existing object has been initialized (which is usually done with the <code>findByKey</code> or <code>findOne</code> method).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a single callback method to run after records are fetched
// In models/User.cfc
config() {
	afterFind(&quot;setFetchedAt&quot;);
}

// The callback receives each row's columns as arguments; return the struct to modify the record.
function setFetchedAt() {
	arguments.fetchedAt = Now();
	return arguments;
}

// 2. Format a column value after a find (works for both query rows and objects)
// In models/Product.cfc
config() {
	afterFind(&quot;formatPrice&quot;);
}

function formatPrice() {
	if (StructKeyExists(arguments, &quot;price&quot;)) {
		arguments.price = DollarFormat(arguments.price);
	}
	return arguments;
}

// 3. Register multiple callback methods as a comma-delimited list
config() {
	afterFind(&quot;setFetchedAt,formatPrice&quot;);
}
</code></pre>
