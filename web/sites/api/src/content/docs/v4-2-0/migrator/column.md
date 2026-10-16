---
title: column()
description: "Adds a column to table definition."
sidebar:
  label: column()
  order: 0
---

## Signature

`column()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds a column to table definition.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnName` | `string` | yes | — |  |
| `columnType` | `string` | yes | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `limit` | `any` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a generic string column to a new table
t = createTable(name='articles');
	t.column(columnName='title', columnType='string', limit=255, allowNull=false);
	t.column(columnName='body', columnType='text');
	t.timestamps();
t.create();

// 2. Add a column with a default value and precision/scale (for decimals)
t = createTable(name='products');
	t.column(columnName='name', columnType='string', limit=100, allowNull=false);
	t.column(columnName='price', columnType='decimal', precision=10, scale=2, default='0.00', allowNull=false);
	t.column(columnName='stock', columnType='integer', default='0', allowNull=false);
	t.timestamps();
t.create();

// 3. Add a custom column when altering an existing table
t = changeTable(name='users');
	t.column(columnName='bio', columnType='text', allowNull=true);
t.change();
</code></pre>
