---
title: errorsOn()
description: "Returns an array of all errors associated with the supplied property (and error name if passed in)."
sidebar:
  label: errorsOn()
  order: 0
---

## Signature

`errorsOn()` — returns `any`




## Description

Returns an array of all errors associated with the supplied property (and error name if passed in).

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Specify the property name to return errors for here. |
| `name` | `string` | yes | — | If you want to return only errors on the above property set with a specific error name you can specify it here. |

</div>

## Examples

<pre>errorsOn(property [, name ]) &lt;!--- Get all errors related to the email address of the user object ---&gt; &lt;cfset errors = user.errorsOn(&quot;emailAddress&quot;)&gt;</pre>
