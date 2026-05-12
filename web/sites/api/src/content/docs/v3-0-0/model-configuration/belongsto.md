---
title: belongsTo()
description: "Sets up a belongsTo association between this model and another model. Use this when the current model contains a foreign key referencing another model. This est"
sidebar:
  label: belongsTo()
  order: 0
---

## Signature

`belongsTo()` — returns `void`

**Available in:** `model`
**Category:** Association Functions

## Description

Sets up a belongsTo association between this model and another model. Use this when the current model contains a foreign key referencing another model. This establishes a one-to-many relationship from the perspective of the other model (i.e., this model “belongs to” a parent model).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example). |
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow Wheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow Wheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow Wheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `inner` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |

</div>

## Examples

<pre><code class='javascript'>1. Standard belongsTo association
// Specify that instances of this model belong to an author
belongsTo("author");

Wheels will automatically deduce the foreign key as authorId and the associated model as Author.

2. Custom foreign key and model name
// Foreign key does not follow convention
belongsTo(name = "bookWriter", modelName = "author", foreignKey = "authorId");

Useful when your database column names or model names deviate from Wheels conventions.

3. Specify LEFT OUTER JOIN
belongsTo(name = "publisher", joinType = "outer");</code></pre>
