---
title: addReference()
description: "Add a foreign key constraint to the database, using the reference name that was used to create it"
sidebar:
  label: addReference()
  order: 0
---

## Signature

`addReference()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Add a foreign key constraint to the database, using the reference name that was used to create it
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceName` | `string` | no | — | The reference table name to perform the operation on |
| `columnName` | `string` | no | — | Alias for `referenceName` (consistent with the modern migrator surface — `columnName` / `columnNames` are accepted alongside the legacy form). |
| `columnNames` | `string` | no | — | Plural alias for `referenceName`. When both `columnName` and `columnNames` are supplied, `columnNames` wins. |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a foreign key from comments.postId to posts.id using a reference name
// Equivalent to: addForeignKey(table=&quot;comments&quot;, referenceTable=&quot;posts&quot;, column=&quot;postId&quot;, referenceColumn=&quot;id&quot;)
addReference(table=&quot;comments&quot;, referenceName=&quot;post&quot;);

// 2. Add a foreign key from order_items.orderId to orders.id
addReference(table=&quot;order_items&quot;, referenceName=&quot;order&quot;);

// 3. Use addReference in a migration's up() and undo it with dropReference() in down()
// In your migration CFC:
//
// public void function up() {
//     addReference(table=&quot;comments&quot;, referenceName=&quot;post&quot;);
// }
//
// public void function down() {
//     dropReference(table=&quot;comments&quot;, referenceName=&quot;post&quot;);
// }
</code></pre>
