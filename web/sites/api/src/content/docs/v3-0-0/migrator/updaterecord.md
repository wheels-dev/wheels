---
title: updateRecord()
description: "Allows you to update an existing record in a database table directly from within a migration CFC. This function is particularly useful when you need to modify d"
sidebar:
  label: updateRecord()
  order: 0
---

## Signature

`updateRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Allows you to update an existing record in a database table directly from within a migration CFC. This function is particularly useful when you need to modify data as part of a schema migration, such as setting default values, correcting legacy data, or updating specific records based on certain conditions. The function requires the table name and optionally allows a where clause to target specific rows. Only available in a migrator CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name where the record is |
| `where` | `string` | no | — | The where clause, i.e admin = 1 |

## Examples

<pre><code class='javascript'>1. Update the `active` column to 0 for all admin users in a migration
updateRecord(table="users", where="admin = 1", active=0);

2. Update a specific product record by ID
updateRecord(table="products", where="id = 42", price=19.99, stock=100);</code></pre>
