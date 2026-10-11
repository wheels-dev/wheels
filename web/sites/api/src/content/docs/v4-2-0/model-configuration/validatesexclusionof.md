---
title: validatesExclusionOf()
description: "Validates that the value of the specified property does not exist in the supplied list."
sidebar:
  label: validatesExclusionOf()
  order: 0
---

## Signature

`validatesExclusionOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property does not exist in the supplied list.



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

<pre><code class='javascript'>// 1. Prevent reserved words from being saved as a programming language name
validatesExclusionOf(property=&quot;language&quot;, list=&quot;php,fortran&quot;, message=&quot;[property] is reserved. Try a real language.&quot;);

// 2. Validate multiple properties against the same exclusion list (e.g. reserved usernames)
validatesExclusionOf(properties=&quot;username,displayName&quot;, list=&quot;admin,root,superuser,moderator&quot;);

// 3. Only enforce the exclusion on create, and skip validation when the value is blank
validatesExclusionOf(property=&quot;referralCode&quot;, list=&quot;FREE,GRATIS,FREEBIE&quot;, when=&quot;onCreate&quot;, allowBlank=true);

// 4. Conditionally enforce the exclusion based on a model property
validatesExclusionOf(property=&quot;status&quot;, list=&quot;banned,suspended&quot;, condition=&quot;this.isAdmin&quot;);
</code></pre>
