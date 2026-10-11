---
title: change()
description: "alters existing table in the database"
sidebar:
  label: change()
  order: 0
---

## Signature

`change()` — returns `void`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

alters existing table in the database



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `addColumns` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Alter existing columns on a table (default behavior — modifies columns that already exist)
t = changeTable(name='users');
	t.string(columnNames='email', limit=255, allowNull=false);
	t.boolean(columnNames='active', default=true, allowNull=false);
t.change();

// 2. Add new columns to an existing table using addColumns=true
t = changeTable(name='products');
	t.string(columnNames='sku', limit=100, allowNull=false);
	t.decimal(columnNames='discountPrice', precision=10, scale=2, allowNull=true);
t.change(addColumns=true);

// 3. Add a foreign key reference column to an existing table
t = changeTable(name='orders');
	t.references(columnNames='customer', allowNull=false);
t.change(addColumns=true);
</code></pre>
