---
title: update()
description: "Updates the object with the supplied <code>properties</code> and saves it to the database."
sidebar:
  label: update()
  order: 0
---

## Signature

`update()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Updates the object with the supplied <code>properties</code> and saves it to the database.
Returns <code>true</code> if the object was saved successfully to the database and <code>false</code> otherwise.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `reload` | `boolean` | no | `false` | Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `allowExplicitTimestamps` | `boolean` | no | `false` | Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties |

</div>

## Examples

<pre><code class='javascript'>// Get a post object and then update its title in the database
post = model(&quot;post&quot;).findByKey(33);
post.update(title=&quot;New version of Wheels just released&quot;);

// Get a post object and then update its title and other properties based on what is pased in from the URL/form
post = model(&quot;post&quot;).findByKey(params.key);
post.update(title=&quot;New version of Wheels just released&quot;, properties=params.post);

// If you have a `hasOne` association setup from `author` to `bio`, you can do a scoped call. (The `setBio` method below will call `bio.update(authorId=anAuthor.id)` internally.)
author = model(&quot;author&quot;).findByKey(params.authorId); 
bio = model(&quot;bio&quot;).findByKey(params.bioId); 
author.setBio(bio); 

// If you have a `hasMany` association setup from `owner` to `car`, you can do a scoped call. (The `addCar` method below will call `car.update(ownerId=anOwner.id)` internally.)
anOwner = model(&quot;owner&quot;).findByKey(params.ownerId); 
aCar = model(&quot;car&quot;).findByKey(params.carId); 
anOwner.addCar(aCar); 

// If you have a `hasMany` association setup from `post` to `comment`, you can do a scoped call. (The `removeComment` method below will call `comment.update(postId=&quot;&quot;)` internally.)
aPost = model(&quot;post&quot;).findByKey(params.postId); 
aComment = model(&quot;comment&quot;).findByKey(params.commentId); 
aPost.removeComment(aComment); // Get an object, and toggle a boolean property
user = model(&quot;user&quot;).findByKey(58); 
isSuccess = user.toggle(&quot;isActive&quot;); // returns whether the object was saved properly

// You can also use a dynamic helper for this
isSuccess = user.toggleIsActive(); 

</code></pre>
