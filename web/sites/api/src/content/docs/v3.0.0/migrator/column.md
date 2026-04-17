---
title: column()
description: "Adds a column to a table definition in a migration. This function is used when defining or altering database tables. It supports multiple column types and allow"
sidebar:
  label: column()
  order: 0
---

## Signature

`column()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds a column to a table definition in a migration. This function is used when defining or altering database tables. It supports multiple column types and allows you to specify constraints like default values, nullability, length, and precision. Use this inside a table definition object in a migration CFC when building or modifying tables.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnName` | `string` | yes | — |  |
| `columnType` | `string` | yes | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `limit` | `any` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |

## Examples

<pre><code class='javascript'>1. Add a string column
t = changeTable(name="employees");
t.column(columnName="fullName", columnType="string", limit=255, allowNull=false, default="Unknown");
t.change();

2. Add a decimal column
t = changeTable(name="products");
t.column(columnName="price", columnType="decimal", precision=10, scale=2, allowNull=false, default="0.00");
t.change();

3. Add a boolean column
t = changeTable(name="members");
t.column(columnName="isActive", columnType="boolean", allowNull=false, default="1");
t.change();</code></pre>
