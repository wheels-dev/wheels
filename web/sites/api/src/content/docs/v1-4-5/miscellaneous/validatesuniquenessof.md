---
title: validatesUniquenessOf()
description: "Validates that the value of the specified property is unique in the database table. Useful for ensuring that two users can't sign up to a website with identical"
sidebar:
  label: validatesUniquenessOf()
  order: 0
---

## Signature

`validatesUniquenessOf()` — returns `any`




## Description

Validates that the value of the specified property is unique in the database table. Useful for ensuring that two users can't sign up to a website with identical usernames for example. When a new record is created, a check is made to make sure that no record already exists in the database table with the given value for the specified property. When the record is updated, the same check is made but disregarding the record itself.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | yes | — | Name of property or list of property names to validate against (can also be called with the property argument). |
| `message` | `string` | yes | `[property] has already been taken` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | yes | `onSave` | Pass in onCreate or onUpdate to limit when this validation occurs (by default, validation will occur on both create and update, i.e. onSave). |
| `allowBlank` | `boolean` | yes | `false` | If set to true, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the validatesPresenceOf test, thus avoiding duplicate error messages if it doesn't. |
| `scope` | `string` | yes | — | One or more properties by which to limit the scope of the uniqueness constraint. |
| `condition` | `string` | yes | — | String expression to be evaluated that decides if validation will be run (if the expression returns true, validation will run). |
| `unless` | `string` | yes | — | String expression to be evaluated that decides if validation will be run (if the expression returns false, validation will run). |
| `includeSoftDeletes` | `boolean` | yes | `true` | Whether to take records deleted using "Soft Delete" into account when performing the uniqueness check. |

</div>

## Examples

<pre>// Make sure that two users with the same username won't ever exist in the database table
validatesUniquenessOf(property=&quot;username&quot;, message=&quot;Sorry, that username is already taken.&quot;);

// Same as above but allow identical usernames as long as they belong to a different account
validatesUniquenessOf(property=&quot;username&quot;, scope=&quot;accountId&quot;);</pre>
