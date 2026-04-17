---
title: addForeignKey()
description: "Adds a foreign key constraint between two tables. This ensures that values in one table’s column must exist in the referenced column of another table, enforcing"
sidebar:
  label: addForeignKey()
  order: 0
---

## Signature

`addForeignKey()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Adds a foreign key constraint between two tables. This ensures that values in one table’s column must exist in the referenced column of another table, enforcing referential integrity. This function is only available inside a migration CFC and is part of the Wheels migrator API.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceTable` | `string` | yes | — | The reference table name to perform the operation on |
| `column` | `string` | yes | — | The column name to perform the operation on |
| `referenceColumn` | `string` | yes | — | The reference column name to perform the operation on |

## Examples

<pre><code class='javascript'>1. Basic foreign key
addForeignKey(
    table=&quot;orders&quot;,
    referenceTable=&quot;users&quot;,
    column=&quot;userId&quot;,
    referenceColumn=&quot;id&quot;
);

Ensures that every orders.userId must exist in users.id.

2. Foreign key for many-to-one relation
addForeignKey(
    table=&quot;comments&quot;,
    referenceTable=&quot;posts&quot;,
    column=&quot;postId&quot;,
    referenceColumn=&quot;id&quot;
);

Ensures each comment is linked to a valid post.

3. Foreign key with a custom reference column
addForeignKey(
    table=&quot;invoices&quot;,
    referenceTable=&quot;customers&quot;,
    column=&quot;customerCode&quot;,
    referenceColumn=&quot;code&quot;
);

Links invoices.customerCode to customers.code instead of a numeric ID.

4. Multiple foreign keys in one migration
// In migration
addForeignKey(
    table=&quot;enrollments&quot;,
    referenceTable=&quot;students&quot;,
    column=&quot;studentId&quot;,
    referenceColumn=&quot;id&quot;
);

addForeignKey(
    table=&quot;enrollments&quot;,
    referenceTable=&quot;courses&quot;,
    column=&quot;courseId&quot;,
    referenceColumn=&quot;id&quot;
);

The enrollments table is linked to both students and courses.</code></pre>
