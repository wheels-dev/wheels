---
title: validatesExclusionOf()
description: "Ensures that the value of a specified property is not included in a given list of disallowed values. This is commonly used to prevent reserved words, restricted"
sidebar:
  label: validatesExclusionOf()
  order: 0
---

## Signature

`validatesExclusionOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Ensures that the value of a specified property is not included in a given list of disallowed values. This is commonly used to prevent reserved words, restricted entries, or disallowed values from being saved to the database. You can specify when the validation should run, allow blank values to skip validation, or conditionally run it.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `list` | `string` | yes | — | Single value or list of values that should not be allowed. |
| `message` | `string` | no | `[property] is reserved` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>1. Prevent users from selecting certain programming languages
validatesExclusionOf(
    property=&quot;coolLanguage&quot;,
    list=&quot;php,fortran&quot;,
    message=&quot;Haha, you can not be serious. Try again, please.&quot;
);

2. Validate multiple properties at once
validatesExclusionOf(
    properties=&quot;username,email&quot;,
    list=&quot;admin,root,system&quot;,
    message=&quot;This value is reserved. Please choose another.&quot;
);

3. Only apply validation on object creation
validatesExclusionOf(
    property=&quot;username&quot;,
    list=&quot;admin,root&quot;,
    when=&quot;onCreate&quot;,
    message=&quot;Username is reserved and cannot be used.&quot;
);

4. Skip validation if the property is blank
validatesExclusionOf(
    property=&quot;nickname&quot;,
    list=&quot;boss,chief&quot;,
    allowBlank=true
);

5. Conditional validation using `condition`
validatesExclusionOf(
    property=&quot;category&quot;,
    list=&quot;deprecated,legacy&quot;,
    condition=&quot;this.isArchived&quot;,
    message=&quot;Archived items cannot use deprecated categories.&quot;
);

6. Skip validation for admin users using `unless`
validatesExclusionOf(
    property=&quot;role&quot;,
    list=&quot;banned,guest&quot;,
    unless=&quot;this.isAdmin&quot;,
    message=&quot;This role is restricted for regular users.&quot;
);
</code></pre>
