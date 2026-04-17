---
title: update()
description: "Updates the object with the supplied properties and saves it to the database. Returns true if the object was saved successfully to the database and false otherw"
sidebar:
  label: update()
  order: 0
---

## Signature

`update()` — returns `any`




## Description

Updates the object with the supplied properties and saves it to the database. Returns true if the object was saved successfully to the database and false otherwise.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | yes | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `parameterize` | `any` | yes | `true` | Set to true to use cfqueryparam on all columns, or pass in a list of property names to use cfqueryparam on those only. |
| `reload` | `boolean` | yes | `false` | Set to true to force Wheels to query the database even though an identical query may have been run in the same request. (The default in Wheels is to get the second query from the request-level cache.) |
| `validate` | `boolean` | yes | `true` | Set to false to skip validations for this operation. |
| `transcation` | `string` | yes | `[runtime expression]` | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |

## Examples

<pre>update([ properties, parameterize, reload, validate, transaction, callbacks ]) &lt;!--- Get a post object and then update its title in the database ---&gt;
&lt;cfset post = model(&quot;post&quot;).findByKey(33)&gt;
&lt;cfset post.update(title=&quot;New version of Wheels just released&quot;)&gt;

&lt;!--- Get a post object and then update its title and other properties based on what is pased in from the URL/form ---&gt;
&lt;cfset post = model(&quot;post&quot;).findByKey(params.key)&gt;
&lt;cfset post.update(title=&quot;New version of Wheels just released&quot;, properties=params.post)&gt;

&lt;!--- If you have a `hasOne` association setup from `author` to `bio`, you can do a scoped call. (The `setBio` method below will call `bio.update(authorId=anAuthor.id)` internally.) ---&gt;
&lt;cfset author = model(&quot;author&quot;).findByKey(params.authorId)&gt;
&lt;cfset bio = model(&quot;bio&quot;).findByKey(params.bioId)&gt;
&lt;cfset author.setBio(bio)&gt;

&lt;!--- If you have a `hasMany` association setup from `owner` to `car`, you can do a scoped call. (The `addCar` method below will call `car.update(ownerId=anOwner.id)` internally.) ---&gt;
&lt;cfset anOwner = model(&quot;owner&quot;).findByKey(params.ownerId)&gt;
&lt;cfset aCar = model(&quot;car&quot;).findByKey(params.carId)&gt;
&lt;cfset anOwner.addCar(aCar)&gt;

&lt;!--- If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `removeComment` method below will call `comment.update(postId=&quot;&quot;)` internally.) ---&gt;
&lt;cfset aPost = model(&quot;post&quot;).findByKey(params.postId)&gt;
&lt;cfset aComment = model(&quot;comment&quot;).findByKey(params.commentId)&gt;
&lt;cfset aPost.removeComment(aComment)&gt;&lt;!--- Get an object, and toggle a boolean property ---&gt;
&lt;cfset user = model(&quot;user&quot;).findByKey(58)&gt;
&lt;cfset isSuccess = user.toggle(&quot;isActive&quot;)&gt;&lt;!--- returns whether the object was saved properly ---&gt;
&lt;!--- You can also use a dynamic helper for this ---&gt;
&lt;cfset isSuccess = user.toggleIsActive()&gt;</pre>
