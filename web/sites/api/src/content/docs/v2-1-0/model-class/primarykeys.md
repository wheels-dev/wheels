---
title: primaryKeys()
description: "Alias for <code>primaryKey()</code>."
sidebar:
  label: primaryKeys()
  order: 0
---

## Signature

`primaryKeys()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Alias for <code>primaryKey()</code>.
Use this for better readability when you're accessing multiple primary keys.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | no | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

## Examples

<pre><code class='javascript'>// Get a list of the names of the primary keys in the table mapped to the `employee` model (which is the `employees` table by default)
keyNames = model(&quot;employee&quot;).primaryKeys();</code></pre>
