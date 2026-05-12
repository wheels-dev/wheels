---
title: clearErrors()
description: "Clears out all errors set on the object or only the ones set for a specific property or name."
sidebar:
  label: clearErrors()
  order: 0
---

## Signature

`clearErrors()` — returns `any`




## Description

Clears out all errors set on the object or only the ones set for a specific property or name.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Specify a property name here if you want to clear all errors set on that property. |
| `name` | `string` | yes | — | Specify an error name here if you want to clear all errors set with that error name. |

</div>

## Examples

<pre>clearErrors([ property, name ]) &lt;!--- Clear all errors on the object as a whole ---&gt;
&lt;cfset this.clearErrors()&gt;

&lt;!--- Clear all errors on `firstName` ---&gt;
&lt;cfset this.clearErrors(&quot;firstName&quot;)&gt;</pre>
