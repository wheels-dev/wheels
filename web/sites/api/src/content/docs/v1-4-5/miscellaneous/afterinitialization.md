---
title: afterInitialization()
description: "Registers method(s) that should be called after an object has been initialized."
sidebar:
  label: afterInitialization()
  order: 0
---

## Signature

`afterInitialization()` — returns `any`




## Description

Registers method(s) that should be called after an object has been initialized.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset afterInitialization(&quot;fixObj&quot;)&gt;</pre>
