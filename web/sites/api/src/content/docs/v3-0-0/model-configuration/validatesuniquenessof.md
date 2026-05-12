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
| `includeSoftDeletes` | `boolean` | no | `true` | Set to `true` to include soft-deleted records in the queries that this method runs. |

</div>

## Examples

<pre><code class='javascript'>1. Ensure that usernames are unique across all users
validatesUniquenessOf(
    property=&quot;username&quot;,
    message=&quot;Sorry, that username is already taken.&quot;
);

2. Ensure that email addresses are unique
validatesUniquenessOf(
    property=&quot;emailAddress&quot;,
    message=&quot;This email has already been registered.&quot;
);

3. Allow the same username in different accounts but unique within an account
validatesUniquenessOf(
    property=&quot;username&quot;,
    scope=&quot;accountId&quot;,
    message=&quot;This username is already used in this account.&quot;
);

4. Only enforce uniqueness if the user is active
validatesUniquenessOf(
    property=&quot;username&quot;,
    condition=&quot;this.isActive&quot;,
    message=&quot;Active users must have a unique username.&quot;
);

5. Skip uniqueness check if the field is blank
validatesUniquenessOf(
    property=&quot;nickname&quot;,
    allowBlank=true,
    message=&quot;Nickname must be unique if supplied.&quot;
);
</code></pre>
