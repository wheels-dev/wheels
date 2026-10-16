---
title: float()
description: "adds float columns to table definition"
sidebar:
  label: float()
  order: 0
---

## Signature

`float()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds float columns to table definition



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | `true` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single float column to a new table
t.float(&quot;price&quot;);

// 2. Add a float column with a default value
t.float(columnNames=&quot;rating&quot;, default=&quot;0.0&quot;);

// 3. Add multiple float columns at once
t.float(&quot;latitude,longitude&quot;);

// 4. Add a float column that does not allow NULL values
t.float(columnNames=&quot;score&quot;, allowNull=false);

// 5. Use float() within a createTable migration
t = createTable(&quot;measurements&quot;);
t.float(&quot;temperature&quot;);
t.float(columnNames=&quot;humidity,pressure&quot;, default=&quot;0.0&quot;);
t.timestamps();
t.create();
</code></pre>
