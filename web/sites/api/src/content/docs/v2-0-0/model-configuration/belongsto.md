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
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow CFWheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow CFWheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow CFWheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `inner` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |

</div>

## Examples

<pre>// Specify that instances of this model belong to an author. (The table for this model should have a foreign key set on it, typically named `authorid`.)
belongsTo(&quot;author&quot;);

// Same as above, but because we have broken away from the foreign key naming convention, we need to set `modelName` and `foreignKey`.
belongsTo(name=&quot;bookWriter&quot;, modelName=&quot;author&quot;, foreignKey=&quot;authorId&quot;);
</pre>
