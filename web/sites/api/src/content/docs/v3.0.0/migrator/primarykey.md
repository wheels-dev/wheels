---
title: primaryKey()
description: "Used inside migration table definitions to define a primary key for the table. By default, it creates a single-column integer primary key, but you can customize"
sidebar:
  label: primaryKey()
  order: 0
---

## Signature

`primaryKey()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used inside migration table definitions to define a primary key for the table. By default, it creates a single-column integer primary key, but you can customize the data type, size, precision, and whether it should auto-increment. If you need composite primary keys, you can call this method multiple times within the same table definition. Additionally, you can configure references to other tables, along with cascading behaviors for updates and deletes. Only available in the migrator CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — |  |
| `type` | `string` | no | `integer` |  |
| `autoIncrement` | `boolean` | no | `false` |  |
| `limit` | `numeric` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |
| `references` | `string` | no | — |  |
| `onUpdate` | `string` | no | — |  |
| `onDelete` | `string` | no | — |  |

## Examples

<pre><code class='javascript'>1. Basic auto-incrementing integer primary key
t.primaryKey(name=&quot;id&quot;, autoIncrement=true);

2. Primary key with custom type
t.primaryKey(name=&quot;sku&quot;, type=&quot;string&quot;, limit=20);

3. Composite primary keys (order_id + product_id)
t.primaryKey(name=&quot;order_id&quot;, type=&quot;integer&quot;);
t.primaryKey(name=&quot;product_id&quot;, type=&quot;integer&quot;);

4. UUID primary key
t.primaryKey(name=&quot;session_id&quot;, type=&quot;uuid&quot;);

5. Primary key with foreign key reference
t.primaryKey(name=&quot;payment_id&quot;, autoIncrement=true);
</code></pre>
