---
title: bigInteger()
description: "Adds one or more big integer columns to a table definition in a migration. Use this when you need columns capable of storing large integer values, typically lar"
sidebar:
  label: bigInteger()
  order: 0
---

## Signature

`bigInteger()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds one or more big integer columns to a table definition in a migration. Use this when you need columns capable of storing large integer values, typically larger than standard integer columns.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `limit` | `numeric` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a single big integer column
bigInteger(columnNames="userId");

2. Add multiple big integer columns
bigInteger(columnNames="orderId, invoiceId");

3. Add a column with a default value and disallow NULLs
bigInteger(columnNames="views", default="0", allowNull=false);

4. Add a column with a custom limit
bigInteger(columnNames="serialNumber", limit=20);</code></pre>
