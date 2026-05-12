---
title: afterNew()
description: "Registers method(s) that should be called after a new object has been initialized (which is usually done with the new method)."
sidebar:
  label: afterNew()
  order: 0
---

## Signature

`afterNew()` — returns `any`




## Description

Registers method(s) that should be called after a new object has been initialized (which is usually done with the new method).

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the method argument). |

</div>

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterNew(&quot;fixObj&quot;)&gt;</pre>
