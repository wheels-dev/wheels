---
title: timestamp()
description: "adds timestamp columns to table definition"
sidebar:
  label: timestamp()
  order: 0
---

## Signature

`timestamp()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds timestamp columns to table definition



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `columnType` | `string` | no | `datetime` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single timestamp column to a new table
t = createTable(name='sessions');
	t.string(columnNames='token', limit=64, allowNull=false);
	t.timestamp(columnNames='expiresAt', allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple timestamp columns at once
t = createTable(name='events');
	t.string(columnNames='name', limit=255, allowNull=false);
	t.timestamp(columnNames='startsAt,endsAt', allowNull=false);
	t.timestamps();
t.create();

// 3. Add a nullable timestamp column with a default to an existing table
t = changeTable(name='articles');
	t.timestamp(columnNames='publishedAt', allowNull=true, default='NOW()');
t.change();

// 4. Override the underlying column type (e.g. use 'timestamp' instead of the default 'datetime')
t = createTable(name='logs');
	t.string(columnNames='message', limit=255, allowNull=false);
	t.timestamp(columnNames='occurredAt', columnType='timestamp', allowNull=false);
	t.timestamps();
t.create();
</code></pre>
