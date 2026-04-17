---
title: afterSave()
description: "Registers method(s) that should be called after an object is saved."
sidebar:
  label: afterSave()
  order: 0
---

## Signature

`afterSave()` — returns `any`




## Description

Registers method(s) that should be called after an object is saved.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterSave(&quot;fixObj&quot;)&gt;</pre>
