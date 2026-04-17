---
title: changeTable()
description: "Creates a table definition object used to store and apply modifications to an existing table in the database. This function is only available inside a migration"
sidebar:
  label: changeTable()
  order: 0
---

## Signature

`changeTable()` — returns `TableDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Creates a table definition object used to store and apply modifications to an existing table in the database. This function is only available inside a migration CFC and works in conjunction with table definition methods like string(), integer(), boolean(), etc., and the change() method to apply the changes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the table to set change properties on |

## Examples

<pre><code class='javascript'>1. Add new columns to an existing table
t = changeTable(name='employees');
t.string(columnNames="fullName", default="", allowNull=true, limit=255);
t.boolean(columnNames="isActive", default=true);
t.change();

2. Modify multiple columns
t = changeTable(name='products');
t.string(columnNames="productName", limit=150, allowNull=false);
t.decimal(columnNames="price", precision=10, scale=2);
t.change();</code></pre>
