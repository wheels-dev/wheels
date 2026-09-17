---
title: bigInteger()
description: "Adds integer columns to table definition."
sidebar:
  label: bigInteger()
  order: 0
---

## Signature

`bigInteger()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds integer columns to table definition.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `limit` | `numeric` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single bigInteger column to a new table
t = createTable(name='events');
	t.bigInteger(columnNames='externalId');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple bigInteger columns at once
t = createTable(name='analytics');
	t.bigInteger(columnNames='pageViews,uniqueVisitors', default=0, allowNull=false);
	t.string(columnNames='path', limit=500, allowNull=false);
	t.timestamps();
t.create();

// 3. Add a bigInteger column with a limit and default when altering an existing table
t = changeTable(name='orders');
	t.bigInteger(columnNames='totalCents', default=0, allowNull=false);
t.change();
</code></pre>
