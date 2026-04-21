---
title: beforeSave()
description: "Registers method(s) that should be called before an object is saved."
sidebar:
  label: beforeSave()
  order: 0
---

## Signature

`beforeSave()` — returns `any`




## Description

Registers method(s) that should be called before an object is saved.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

</div>

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `fixObj` method ---&gt;
&lt;cfset beforeSave(&quot;fixObj&quot;)&gt;</pre>
