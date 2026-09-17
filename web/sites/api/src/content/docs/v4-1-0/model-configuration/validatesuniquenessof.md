---
title: validatesUniquenessOf()
description: "Validates that the value of the specified property is unique in the database table."
sidebar:
  label: validatesUniquenessOf()
  order: 0
---

## Signature

`validatesUniquenessOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property is unique in the database table.
Useful for ensuring that two users can't sign up to a website with identical usernames for example.
When a new record is created, a check is made to make sure that no record already exists in the database table with the given value for the specified property.
When the record is updated, the same check is made but disregarding the record itself.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] has already been taken` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `scope` | `string` | no | — | One or more properties by which to limit the scope of the uniqueness constraint. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |

</div>

## Examples

<pre><code class='javascript'>// 1. Ensure no two users share the same username
validatesUniquenessOf(property=&quot;username&quot;, message=&quot;Sorry, that username is already taken.&quot;);

// 2. Scope uniqueness to an account — the same username is allowed in different accounts
validatesUniquenessOf(property=&quot;username&quot;, scope=&quot;accountId&quot;);

// 3. Validate multiple properties for uniqueness in one call
validatesUniquenessOf(properties=&quot;email,username&quot;);

// 4. Skip the check when the email field is blank (pair with validatesPresenceOf to avoid duplicate errors)
validatesUniquenessOf(property=&quot;email&quot;, allowBlank=true);

// 5. Only enforce uniqueness on create, not on update
validatesUniquenessOf(property=&quot;slug&quot;, when=&quot;onCreate&quot;);

// 6. Run the check only when a condition is true
validatesUniquenessOf(property=&quot;referralCode&quot;, condition=&quot;this.isAffiliate()&quot;);

// 7. Include soft-deleted records in the uniqueness check so a previously-deleted value stays reserved
validatesUniquenessOf(property=&quot;username&quot;, includeSoftDeletes=true);
</code></pre>
