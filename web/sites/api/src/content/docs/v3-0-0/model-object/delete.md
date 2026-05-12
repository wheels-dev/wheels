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

<pre><code class='javascript'>Example 1: Delete a single object
&lt;cfscript&gt;
post = model("post").findByKey(33);
success = post.delete();
&lt;/cfscript&gt;

Deletes the post with ID 33 from the database.

Returns true if deletion succeeds.

Example 2: Scoped delete via association
&lt;cfscript&gt;
post = model("post").findByKey(params.postId);
comment = model("comment").findByKey(params.commentId);

// Calls comment.delete() internally
post.deleteComment(comment);
&lt;/cfscript&gt;

If post has a hasMany association to comment, this uses the association method to delete a related comment.

Example 3: Permanent deletion (bypass soft-delete)
&lt;cfscript&gt;
post = model("post").findByKey(33);
post.delete(softDelete=false);
&lt;/cfscript&gt;

Forces a hard delete even if the model uses soft-delete columns.</code></pre>
