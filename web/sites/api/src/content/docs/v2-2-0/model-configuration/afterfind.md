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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument). |

## Examples

<pre><code class='javascript'>// Instruct CFWheels to call the `setTime` method after getting objects or records with one of the finder methods.
config() {
	afterFind(&quot;setTime&quot;);
}

function setTime(){
	arguments.fetchedAt = Now();
	return arguments;
}
</code></pre>
