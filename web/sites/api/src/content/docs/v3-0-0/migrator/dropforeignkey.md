---
title: dropForeignKey()
description: "dropForeignKey() is used to remove a foreign key constraint from a table in the database. This is typically done during schema changes in migrations. Only avail"
sidebar:
  label: dropForeignKey()
  order: 0
---

## Signature

`dropForeignKey()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

dropForeignKey() is used to remove a foreign key constraint from a table in the database. This is typically done during schema changes in migrations. Only available in a migration CFC.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `keyName` | `string` | yes | — | the name of the key to drop |

</div>

## Examples

<pre><code class='javascript'>function up() {
    // Remove a foreign key from the orders table
    dropForeignKey(
        table="orders",
        keyName="fk_orders_customerId"
    );
}

table = "orders" -> the table that has the foreign key.

keyName = "fk_orders_customerId" -> the exact name of the foreign key constraint you want to drop.</code></pre>
