---
title: delete()
description: "Deletes the object, which means the row is deleted from the database (unless prevented by a beforeDelete callback). Returns true on successful deletion of the r"
sidebar:
  label: delete()
  order: 0
---

## Signature

`delete()` — returns `any`




## Description

Deletes the object, which means the row is deleted from the database (unless prevented by a beforeDelete callback). Returns true on successful deletion of the row, false otherwise.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `transaction` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |
| `includeSoftDeletes` | `boolean` | yes | `false` | You can set this argument to true to include soft-deleted records in the results. |
| `softDelete` | `boolean` | yes | `true` | Set to false to permanently delete a record, even if it has a soft delete column. |

## Examples

<pre>delete([ parameterize, transaction, callbacks, includeSoftDeletes, softDelete ]) &lt;!--- Get a post object and then delete it from the database ---&gt;
&lt;cfset post = model(&quot;post&quot;).findByKey(33)&gt;
&lt;cfset post.delete()&gt;

&lt;!--- If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `deleteComment` method below will call `comment.delete()` internally.) ---&gt;
&lt;cfset post = model(&quot;post&quot;).findByKey(params.postId)&gt;
&lt;cfset comment = model(&quot;comment&quot;).findByKey(params.commentId)&gt;
&lt;cfset post.deleteComment(comment)&gt;</pre>
