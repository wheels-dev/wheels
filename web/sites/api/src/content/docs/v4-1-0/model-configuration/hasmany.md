---
title: hasMany()
description: "Sets up a <code>hasMany</code> association between this model and the specified one."
sidebar:
  label: hasMany()
  order: 0
---

## Signature

`hasMany()` — returns `void`

**Available in:** `model`
**Category:** Association Functions

## Description

Sets up a <code>hasMany</code> association between this model and the specified one.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example). |
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow Wheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow Wheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow Wheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `outer` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |
| `dependent` | `string` | no | `false` | Defines how to handle dependent model objects when you delete an object from this model. `delete` / `deleteAll` deletes the record(s) (`deleteAll` bypasses object instantiation). `remove` / `removeAll` sets the forein key field(s) to `NULL` (`removeAll` bypasses object instantiation). |
| `shortcut` | `string` | no | — | Set this argument to create an additional dynamic method that gets the object(s) from the other side of a many-to-many association. |
| `through` | `string` | no | `[runtime expression]` | Set this argument if you need to override Wheels conventions when using the `shortcut` argument. Accepts a list of two association names representing the chain from the opposite side of the many-to-many relationship to this model. |
| `as` | `string` | no | — | Set this argument to declare a polymorphic `hasMany` association. The child model stores the parent type in a `{as}Type` column alongside the foreign key `{as}Id`. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic usage – a Post has many comments (foreign key `postId` lives on the `comments` table)
// In models/Post.cfc config()
hasMany(&quot;comments&quot;);

// 2. Set up a many-to-many shortcut so readers can access publications directly
// In models/Reader.cfc config()
hasMany(name=&quot;subscriptions&quot;, shortcut=&quot;publications&quot;);

// 3. Automatically delete all associated comments (bypassing object instantiation) when the parent is deleted
// In models/Post.cfc config()
hasMany(name=&quot;comments&quot;, dependent=&quot;deleteAll&quot;);

// 4. Instantiate and call each comment's beforeDelete callback when deleting dependents
// In models/Post.cfc config()
hasMany(name=&quot;comments&quot;, dependent=&quot;delete&quot;);

// 5. Override the many-to-many shortcut chain when association names differ from model names
// In models/Customer.cfc config()
hasMany(name=&quot;subscriptions&quot;, shortcut=&quot;magazines&quot;, through=&quot;publication,subscriptions&quot;);
// In models/Subscription.cfc config()
belongsTo(&quot;customer&quot;);
belongsTo(&quot;publication&quot;);
// In models/Publication.cfc config()
hasMany(&quot;subscriptions&quot;);

// 6. Specify a custom foreign key when not following Wheels naming conventions
// In models/Author.cfc config()
hasMany(name=&quot;articles&quot;, foreignKey=&quot;writtenByAuthorId&quot;);

// 7. Use an inner join instead of the default outer join when including the association
// In models/Category.cfc config()
hasMany(name=&quot;products&quot;, joinType=&quot;inner&quot;);

// 8. Polymorphic hasMany – a model acts as a parent for a shared `comments` child model
// In models/Photo.cfc config() (the `as` value matches the `polymorphic` interface name on the child)
hasMany(name=&quot;comments&quot;, as=&quot;commentable&quot;);
// In models/Comment.cfc config()
belongsTo(name=&quot;commentable&quot;, polymorphic=true);
</code></pre>
