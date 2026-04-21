---
title: time()
description: "Adds one or more TIME columns to a table definition in a migration. Only available in a migrator CFC."
sidebar:
  label: time()
  order: 0
---

## Signature

`time()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds one or more TIME columns to a table definition in a migration. Only available in a migrator CFC.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a simple time column
t.time(&quot;startTime&quot;)

2. Add multiple time columns
t.time(&quot;opensAt, closesAt&quot;)

3. Add a time column with a default value
t.time(columnNames=&quot;reminderAt&quot;, default=&quot;09:00:00&quot;)

4. Add a nullable time column
t.time(columnNames=&quot;lunchBreak&quot;, allowNull=true)
</code></pre>
