---
title: timestamps()
description: "adds Wheels convention automatic timestamp and soft delete columns to table definition"
sidebar:
  label: timestamps()
  order: 0
---

## Signature

`timestamps()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds Wheels convention automatic timestamp and soft delete columns to table definition




## Examples

<pre><code class='javascript'>// 1. Add Wheels convention timestamp and soft-delete columns to a new table
// Adds createdAt, updatedAt, and deletedAt (all nullable datetime columns)
t = createTable(name='articles');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.text(columnNames='body');
	t.timestamps();
t.create();

// 2. Use timestamps() alongside other column definitions in a full migration
t = createTable(name='posts');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.string(columnNames='slug', limit=255, allowNull=false);
	t.text(columnNames='body');
	t.boolean(columnNames='published', default=false, allowNull=false);
	t.references(columnNames='author');
	t.timestamps();
t.create();
</code></pre>
