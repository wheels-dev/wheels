---
title: beforeCreate()
description: "Registers method(s) that should be called before a new object is created."
sidebar:
  label: beforeCreate()
  order: 0
---

## Signature

`beforeCreate()` — returns `any`




## Description

Registers method(s) that should be called before a new object is created.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeCreate(&quot;fixObj&quot;)&gt;</pre>
