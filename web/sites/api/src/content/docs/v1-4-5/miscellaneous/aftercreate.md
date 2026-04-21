---
title: afterCreate()
description: "Registers method(s) that should be called after a new object is created."
sidebar:
  label: afterCreate()
  order: 0
---

## Signature

`afterCreate()` — returns `any`




## Description

Registers method(s) that should be called after a new object is created.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

</div>

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterCreate(&quot;fixObj&quot;)&gt;</pre>
