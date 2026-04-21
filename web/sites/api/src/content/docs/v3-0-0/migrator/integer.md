---
title: integer()
description: "Adds one or more integer columns to a table definition during a migration. You can optionally specify a limit, default value, and whether the column allows NULL"
sidebar:
  label: integer()
  order: 0
---

## Signature

`integer()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds one or more integer columns to a table definition during a migration. You can optionally specify a limit, default value, and whether the column allows NULL. Only available in migrator CFC.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `limit` | `numeric` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a single integer column age
t.integer(&quot;age&quot;)

2. Add multiple integer columns height and weight
t.integer(&quot;height,weight&quot;)

3. Add an integer column quantity with a default value of 0
t.integer(columnNames=&quot;quantity&quot;, default=0)

4. Add an integer column priority that cannot be null
t.integer(columnNames=&quot;priority&quot;, allowNull=false)

5. Add an integer column rating with a limit of 2 digits (smallint)
t.integer(columnNames=&quot;rating&quot;, limit=2)

6. Add multiple columns with different limits (comma-separated)
t.integer(columnNames=&quot;smallValue,mediumValue,bigValue&quot;, limit=1)
</code></pre>
