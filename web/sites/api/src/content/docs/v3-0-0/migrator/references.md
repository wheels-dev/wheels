---
title: references()
description: "Used when defining a table schema to add reference columns that act as foreign keys, linking the table to other tables in the database. It automatically creates"
sidebar:
  label: references()
  order: 0
---

## Signature

`references()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used when defining a table schema to add reference columns that act as foreign keys, linking the table to other tables in the database. It automatically creates integer columns for the references and sets up foreign key constraints, helping maintain referential integrity. You can customize the behavior of these reference columns, including whether they allow nulls, default values, or support polymorphic associations. You can also define actions for ON UPDATE and ON DELETE events.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `referenceNames` | `string` | yes | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | `false` |  |
| `polymorphic` | `boolean` | no | `false` |  |
| `foreignKey` | `boolean` | no | `true` |  |
| `onUpdate` | `string` | no | — |  |
| `onDelete` | `string` | no | — |  |

## Examples

<pre><code class='javascript'>1. Basic reference column
t.references(&quot;userId&quot;);

2. Multiple references with nulls allowed
t.references(referenceNames=&quot;userId,orderId&quot;, allowNull=true);

3. Reference with default value
t.references(referenceNames=&quot;statusId&quot;, default=1);

4. Polymorphic reference (used in polymorphic associations)
t.references(referenceNames=&quot;referenceableId&quot;, polymorphic=true);

5. Custom foreign key actions
t.references(
    referenceNames=&quot;customerId&quot;,
    onUpdate=&quot;CASCADE&quot;,
    onDelete=&quot;SET NULL&quot;
);
</code></pre>
