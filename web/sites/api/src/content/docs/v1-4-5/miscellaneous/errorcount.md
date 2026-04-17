---
title: errorCount()
description: "Returns the number of errors this object has associated with it. Specify property or name if you wish to count only specific errors."
sidebar:
  label: errorCount()
  order: 0
---

## Signature

`errorCount()` — returns `any`




## Description

Returns the number of errors this object has associated with it. Specify property or name if you wish to count only specific errors.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Specify a property name here if you want to count only errors set on a specific property. |
| `name` | `string` | yes | — | Specify an error name here if you want to count only errors set with a specific error name. |

## Examples

<pre>errorCount([ property, name ]) &lt;!--- Check how many errors are set on the object ---&gt;
&lt;cfif author.errorCount() GTE 10&gt;
    &lt;!--- Do something to deal with this very erroneous author here... ---&gt;
&lt;/cfif&gt;

&lt;!--- Check how many errors are associated with the `email` property ---&gt;
&lt;cfif author.errorCount(&quot;email&quot;) gt 0&gt;
    &lt;!--- Do something to deal with this erroneous author here... ---&gt;
&lt;/cfif&gt;</pre>
