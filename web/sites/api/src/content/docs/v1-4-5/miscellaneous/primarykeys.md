---
title: primaryKeys()
description: "Alias for primaryKey(). Use this for better readability when you're accessing multiple primary keys."
sidebar:
  label: primaryKeys()
  order: 0
---

## Signature

`primaryKeys()` — returns `any`




## Description

Alias for primaryKey(). Use this for better readability when you're accessing multiple primary keys.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `position` | `numeric` | yes | `0` | If you are accessing a composite primary key, pass the position of a single key to fetch. |

## Examples

<pre>primaryKeys([ position ]) &lt;!--- Get a list of the names of the primary keys in the table mapped to the `employee` model (which is the `employees` table by default) ---&gt;
&lt;cfset keyNames = model(&quot;employee&quot;).primaryKeys()&gt;</pre>
