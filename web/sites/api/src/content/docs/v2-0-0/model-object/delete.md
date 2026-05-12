---
title: delete()
description: "Deletes the object, which means the row is deleted from the database (unless prevented by a <code>beforeDelete</code> callback)."
sidebar:
  label: delete()
  order: 0
---

## Signature

`delete()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Deletes the object, which means the row is deleted from the database (unless prevented by a <code>beforeDelete</code> callback).
Returns <code>true</code> on successful deletion of the row, <code>false</code> otherwise.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `softDelete` | `boolean` | no | `true` | Set to `false` to permanently delete a record, even if it has a soft delete column. |

</div>

## Examples

<pre>// Get a post object and then delete it from the database.
post = model(&quot;post&quot;).findByKey(33);
post.delete();

// If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `deleteComment` method below will call `comment.delete()` internally.)
post = model(&quot;post&quot;).findByKey(params.postId);
comment = model(&quot;comment&quot;).findByKey(params.commentId);
post.deleteComment(comment);</pre>
