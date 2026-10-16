---
title: dropReference()
description: "Drop a foreign key constraint from the database, using the reference name that was used to create it"
sidebar:
  label: dropReference()
  order: 0
---

## Signature

`dropReference()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Drop a foreign key constraint from the database, using the reference name that was used to create it
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceName` | `string` | no | — | the name of the reference to drop |
| `columnName` | `string` | no | — | Alias for `referenceName` (consistent with the modern migrator surface — `columnName` / `columnNames` are accepted alongside the legacy form). |
| `columnNames` | `string` | no | — | Plural alias for `referenceName`. When both `columnName` and `columnNames` are supplied, `columnNames` wins. |

</div>

## Examples

<pre><code class='javascript'>// 1. Drop the foreign key from comments.postId back to posts.id
// Removes the constraint named FK_comments_posts
dropReference(table=&quot;comments&quot;, referenceName=&quot;post&quot;);

// 2. Drop a foreign key from order_items back to orders
// Removes the constraint named FK_order_items_orders
dropReference(table=&quot;order_items&quot;, referenceName=&quot;order&quot;);

// 3. Use dropReference in the down() of a migration that added a reference in up()
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
