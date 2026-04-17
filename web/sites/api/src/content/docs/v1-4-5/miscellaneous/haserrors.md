---
title: hasErrors()
description: "Returns true if the object has any errors. You can also limit to only check a specific property or name for errors."
sidebar:
  label: hasErrors()
  order: 0
---

## Signature

`hasErrors()` — returns `any`




## Description

Returns true if the object has any errors. You can also limit to only check a specific property or name for errors.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of the property to check if there are any errors set on. |
| `name` | `string` | yes | — | Error name to check if there are any errors set with. |

## Examples

<pre>hasErrors([ property, name ]) &lt;!--- Check if the post object has any errors set on it ---&gt;
&lt;cfif post.hasErrors()&gt;
    &lt;!--- Send user to a form to correct the errors... ---&gt;
&lt;/cfif&gt;</pre>
