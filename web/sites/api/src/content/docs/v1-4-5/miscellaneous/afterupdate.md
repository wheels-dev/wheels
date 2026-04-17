---
title: afterUpdate()
description: "Registers method(s) that should be called after an existing object is updated."
sidebar:
  label: afterUpdate()
  order: 0
---

## Signature

`afterUpdate()` — returns `any`




## Description

Registers method(s) that should be called after an existing object is updated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterUpdate(&quot;fixObj&quot;)&gt;</pre>
