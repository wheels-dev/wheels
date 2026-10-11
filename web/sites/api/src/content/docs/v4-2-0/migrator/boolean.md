---
title: boolean()
description: "Adds boolean columns to table definition."
sidebar:
  label: boolean()
  order: 0
---

## Signature

`boolean()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds boolean columns to table definition.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single boolean column to a new table
t = createTable(name='products');
	t.string(columnNames='name', limit=255, allowNull=false);
	t.boolean(columnNames='isActive', default=1, allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple boolean columns at once
t = createTable(name='users');
	t.string(columnNames='email', limit=255, allowNull=false);
	t.boolean(columnNames='isAdmin,isVerified,isActive', default=0, allowNull=false);
	t.timestamps();
t.create();

// 3. Add a boolean column to an existing table
t = changeTable(name='articles');
	t.boolean(columnNames='isPublished', default=0, allowNull=false);
t.change();
</code></pre>
