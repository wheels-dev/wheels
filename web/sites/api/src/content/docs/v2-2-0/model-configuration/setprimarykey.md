---
title: setPrimaryKey()
description: "Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s)."
sidebar:
  label: setPrimaryKey()
  order: 0
---

## Signature

`setPrimaryKey()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s).
Pass as a list if defining a composite primary key.
This function is also aliased as <code>setPrimaryKeys()</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Property (or list of properties) to set as the primary key. |

## Examples

<pre><code class='javascript'>// In `models/User.cfc`, define the primary key as a column called `userID`.
function config(){
	setPrimaryKey(&quot;userID&quot;);
}</code></pre>
