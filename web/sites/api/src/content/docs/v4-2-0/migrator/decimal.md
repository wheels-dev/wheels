---
title: decimal()
description: "adds decimal columns to table definition"
sidebar:
  label: decimal()
  order: 0
---

## Signature

`decimal()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds decimal columns to table definition



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single decimal column to a new table
t = createTable(name='products');
	t.string(columnNames='name', limit=255, allowNull=false);
	t.decimal(columnNames='price', precision=10, scale=2, allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple decimal columns at once
t = createTable(name='measurements');
	t.string(columnNames='label', limit=100, allowNull=false);
	t.decimal(columnNames='length,width,height', precision=8, scale=4, allowNull=false);
	t.timestamps();
t.create();

// 3. Add a nullable decimal column with a default to an existing table
t = changeTable(name='orders');
	t.decimal(columnNames='discount', precision=5, scale=2, allowNull=true, default='0.00');
t.change();
</code></pre>
