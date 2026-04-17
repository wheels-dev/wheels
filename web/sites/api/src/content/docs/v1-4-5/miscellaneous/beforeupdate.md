---
title: beforeUpdate()
description: "Registers method(s) that should be called before an existing object is updated."
sidebar:
  label: beforeUpdate()
  order: 0
---

## Signature

`beforeUpdate()` — returns `any`




## Description

Registers method(s) that should be called before an existing object is updated.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeUpdate(&quot;fixObj&quot;)&gt;</pre>
