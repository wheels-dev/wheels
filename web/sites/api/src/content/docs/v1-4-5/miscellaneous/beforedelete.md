---
title: beforeDelete()
description: "Registers method(s) that should be called before an object is deleted."
sidebar:
  label: beforeDelete()
  order: 0
---

## Signature

`beforeDelete()` — returns `any`




## Description

Registers method(s) that should be called before an object is deleted.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

</div>

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeDelete(&quot;fixObj&quot;)&gt;</pre>
