---
title: dropReference()
description: "dropReference() is used to remove a foreign key constraint from a table in the database using the reference name that was originally used to create it. This is"
sidebar:
  label: dropReference()
  order: 0
---

## Signature

`dropReference()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

dropReference() is used to remove a foreign key constraint from a table in the database using the reference name that was originally used to create it. This is slightly different from dropForeignKey(), which requires the actual key name. Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceName` | `string` | yes | — | the name of the reference to drop |

## Examples

<pre><code class='javascript'>function up() {
    // Remove a foreign key reference from the orders table
    dropReference(
        table="orders",
        referenceName="customer_ref"
    );
}

table = "orders" -> the table that contains the foreign key reference.

referenceName = "customer_ref" -> the reference name that was originally defined when the foreign key was created.</code></pre>
