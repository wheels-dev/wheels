---
title: errorsOnBase()
description: "Returns an array of all errors associated with the object as a whole (not related to any specific property)."
sidebar:
  label: errorsOnBase()
  order: 0
---

## Signature

`errorsOnBase()` — returns `any`




## Description

Returns an array of all errors associated with the object as a whole (not related to any specific property).

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Specify an error name here to only return errors for that error name. |

## Examples

<pre>errorsOnBase([ name ]) &lt;!--- Get all general type errors for the user object ---&gt;
&lt;cfset errors = user.errorsOnBase()&gt;</pre>
