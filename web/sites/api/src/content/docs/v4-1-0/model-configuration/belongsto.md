---
title: belongsTo()
description: "Sets up a <code>belongsTo</code> association between this model and the specified one."
sidebar:
  label: belongsTo()
  order: 0
---

## Signature

`belongsTo()` — returns `void`

**Available in:** `model`
**Category:** Association Functions

## Description

Sets up a <code>belongsTo</code> association between this model and the specified one.
Use this association when this model contains a foreign key referencing another model.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example). |
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow Wheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow Wheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow Wheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `inner` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |
| `polymorphic` | `boolean` | no | `false` | Set to `true` to declare a polymorphic `belongsTo` association. The foreign key defaults to `{name}Id` and a `{name}Type` column is used to store the owning model name at runtime. |

</div>

## Examples

<pre><code class='javascript'>// 1. Specify that instances of this model belong to an author.
// (The table for this model should have a foreign key column, typically named `authorId`.)
belongsTo(&quot;author&quot;);

// 2. Override naming conventions by specifying `modelName` and `foreignKey` explicitly.
belongsTo(name=&quot;bookWriter&quot;, modelName=&quot;author&quot;, foreignKey=&quot;authorId&quot;);

// 3. Use a LEFT OUTER JOIN instead of the default INNER JOIN when including this association.
belongsTo(name=&quot;category&quot;, joinType=&quot;outer&quot;);

// 4. Declare a polymorphic belongsTo association (e.g. a Comment that can belong to a Post or a Photo).
// Wheels will look for `commentableId` and `commentableType` columns on the comments table.
belongsTo(name=&quot;commentable&quot;, polymorphic=true);
</code></pre>
