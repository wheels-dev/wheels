---
title: protectedProperties()
description: "Used to protect one or more model properties from being set or modified through mass assignment operations. Mass assignment occurs when values are assigned to a"
sidebar:
  label: protectedProperties()
  order: 0
---

## Signature

`protectedProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Used to protect one or more model properties from being set or modified through mass assignment operations. Mass assignment occurs when values are assigned to a model in bulk, such as through create(), update(), or updateAll() using a struct of data. By marking certain properties as protected, you can prevent accidental or malicious changes to sensitive fields (such as id, role, or passwordHash). This method is typically called in the model’s config() function to define rules that apply across the entire model.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Property name (or list of property names) that are not allowed to be altered through mass assignment. |

## Examples

<pre><code class='javascript'>// In `app/models/User.cfc`, `firstName` and `lastName` cannot be changed through mass assignment operations like `updateAll()`.
function config(){
	protectedProperties(&quot;firstName,lastName&quot;);
}
</code></pre>
