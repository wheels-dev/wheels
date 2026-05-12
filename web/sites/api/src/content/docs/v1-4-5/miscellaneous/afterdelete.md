---
title: afterDelete()
description: "Registers method(s) that should be called after an object is deleted."
sidebar:
  label: afterDelete()
  order: 0
---

## Signature

`afterDelete()` — returns `any`




## Description

Registers method(s) that should be called after an object is deleted.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

</div>

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterDelete(&quot;fixObj&quot;)&gt;</pre>
