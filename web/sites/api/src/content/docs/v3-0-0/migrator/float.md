---
title: float()
description: "The float() function is used in a table definition during a migration to add one or more float-type columns to a database table. You can specify column names, d"
sidebar:
  label: float()
  order: 0
---

## Signature

`float()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

The float() function is used in a table definition during a migration to add one or more float-type columns to a database table. You can specify column names, default values, and whether the columns allow NULL. This helps define numeric columns with decimal values in your schema. Only available in a migrator CFC.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | `true` |  |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage: add a single float column
t.float(&quot;price&quot;);

2. Add multiple float columns at once
t.float(&quot;length,width,height&quot;);

3. Add a float column with a default value
t.float(columnNames=&quot;discount&quot;, default=&quot;0.0&quot;);

4. Add a float column that cannot be null
t.float(columnNames=&quot;taxRate&quot;, allowNull=false);

5. Add multiple float columns with defaults
t.float(columnNames=&quot;latitude,longitude&quot;, default=&quot;0.0&quot;);

6. Combine default value and null constraint
t.float(columnNames=&quot;weight&quot;, default=&quot;1.0&quot;, allowNull=false);
</code></pre>
