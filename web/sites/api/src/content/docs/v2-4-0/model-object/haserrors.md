---
title: hasErrors()
description: "Returns <code>true</code> if the object has any errors."
sidebar:
  label: hasErrors()
  order: 0
---

## Signature

`hasErrors()` — returns `boolean`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns <code>true</code> if the object has any errors.
You can also limit to only check a specific property or name for errors.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to check if there are any errors set on. |
| `name` | `string` | no | — | Error name to check if there are any errors set with. |

## Examples

<pre><code class='javascript'>// Check if the post object has any errors set on it 
if(post.hasErrors()){
    // Send user to a form to correct the errors... 
}</code></pre>
