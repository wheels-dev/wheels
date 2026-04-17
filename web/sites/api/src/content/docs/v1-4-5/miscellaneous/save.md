---
title: save()
description: "Saves the object if it passes validation and callbacks. Returns true if the object was saved successfully to the database, false if not."
sidebar:
  label: save()
  order: 0
---

## Signature

`save()` — returns `any`




## Description

Saves the object if it passes validation and callbacks. Returns true if the object was saved successfully to the database, false if not.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `parameterize` | `any` | yes | `true` | See documentation for findAll. |
| `reload` | `boolean` | yes | `false` | Set to true to reload the object from the database once an insert/update has completed. |
| `validate` | `boolean` | yes | `true` | Set to false to skip validations for this operation. |
| `transaction` | `string` | yes | — | Set this to commit to update the database when the save has completed, rollback to run all the database queries but not commit them, or none to skip transaction handling altogether. |
| `callbacks` | `boolean` | yes | `true` | Set to false to disable callbacks for this operation. |

## Examples

<pre>&lt;!--- Save the user object to the database (will automatically do an `INSERT` or `UPDATE` statement depending on if the record is new or already exists ---&gt;
&lt;cfset user.save()&gt;

&lt;!--- Save the user object directly in an if statement without using `cfqueryparam` and take appropriate action based on the result ---&gt;
&lt;cfif user.save(parameterize=false)&gt;
	&lt;cfset flashInsert(notice=&quot;The user was saved!&quot;)&gt;
	&lt;cfset redirectTo(action=&quot;edit&quot;)&gt;
&lt;cfelse&gt;
	&lt;cfset flashInsert(alert=&quot;Error, please correct!&quot;)&gt;
	&lt;cfset renderPage(action=&quot;edit&quot;)&gt;
&lt;/cfif&gt;</pre>
