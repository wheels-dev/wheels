---
title: dropTable()
description: "dropTable() is used to remove a table from the database entirely. This is a destructive operation, so all data in the table will be lost. Only available in a mi"
sidebar:
  label: dropTable()
  order: 0
---

## Signature

`dropTable()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

dropTable() is used to remove a table from the database entirely. This is a destructive operation, so all data in the table will be lost. Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the table to drop |

</div>

## Examples

<pre><code class='javascript'>function down() {
    // Drop the 'users' table
    dropTable(name="users");
}

name = "users" -> the table that you want to remove from the database.

Notes

Typically used in the down() method of a migration when rolling back a previous createTable().

Can be combined with transaction {} to ensure rollback in case of errors:

function down() {
    transaction {
        try {
            dropTable("orders");
        } catch (any e) {
            transaction action="rollback";
            throw(errorCode="1", detail=e.detail, message=e.message, type="any");
        }
        transaction action="commit";
    }
}

Caution: This operation permanently deletes all data in the table.</code></pre>
