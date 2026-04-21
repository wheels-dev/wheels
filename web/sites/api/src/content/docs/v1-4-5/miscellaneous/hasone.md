---
title: hasOne()
description: "Sets up a hasOne association between this model and the specified one."
sidebar:
  label: hasOne()
  order: 0
---

## Signature

`hasOne()` — returns `any`




## Description

Sets up a hasOne association between this model and the specified one.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for belongsTo. |
| `modelName` | `string` | yes | — | See documentation for belongsTo. |
| `foreignKey` | `string` | yes | — | See documentation for belongsTo. |
| `joinKey` | `string` | yes | — | See documentation for belongsTo. |
| `joinType` | `string` | yes | `outer` | See documentation for belongsTo. |
| `dependent` | `string` | yes | `false` | See documentation for hasMany. |

</div>

## Examples

<pre>// Specify that instances of this model has one profile. (The table for the associated model, not the current, should have the foreign key set on it.)
hasOne(&quot;profile&quot;);

// Same as above but setting the `joinType` to `inner`, which basically means this model should always have a record in the `profiles` table
hasOne(name=&quot;profile&quot;, joinType=&quot;inner&quot;);

// Automatically delete the associated `profile` whenever this object is deleted
hasMany(name=&quot;comments&quot;, dependent=&quot;delete&quot;);</pre>
