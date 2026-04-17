---
title: decimal()
description: "Adds decimal (numeric) columns to a table definition when creating or altering tables via a migration CFC."
sidebar:
  label: decimal()
  order: 0
---

## Signature

`decimal()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds decimal (numeric) columns to a table definition when creating or altering tables via a migration CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |

## Examples

<pre><code class='javascript'>Example 1: Basic decimal column
t = changeTable("products");
t.decimal(columnNames="price", default="0.00", allowNull=false, precision=10, scale=2);
t.change();

Adds a price column with up to 10 digits, 2 of which are after the decimal point, default 0.00, and cannot be NULL.

---

Example 2: Multiple decimal columns
t = changeTable("invoices");
t.decimal(columnNames="tax,discount", default="0.00", allowNull=false, precision=8, scale=2);
t.change();

Adds tax and discount columns with the same configuration.

---

Example 3: Nullable decimal column with no default
t = createTable("payments");
t.decimal(columnNames="amountDue", allowNull=true, precision=12, scale=4);
t.create();

Adds a amountDue column that can be NULL and allows up to 12 digits, 4 of which are after the decimal.</code></pre>
