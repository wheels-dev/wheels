---
title: validatesInclusionOf()
description: "Validates that the value of the specified property exists in the supplied list."
sidebar:
  label: validatesInclusionOf()
  order: 0
---

## Signature

`validatesInclusionOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property exists in the supplied list.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `list` | `string` | yes | — | List of allowed values. |
| `message` | `string` | no | `[property] is not included in the list` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>// 1. Validate that a user selects a valid framework choice
validatesInclusionOf(property=&quot;frameworkOfChoice&quot;, list=&quot;cfwheels,rails,django&quot;, message=&quot;Please select a supported framework.&quot;);

// 2. Validate a status field and skip validation if the value is blank
validatesInclusionOf(property=&quot;status&quot;, list=&quot;active,inactive,pending&quot;, allowBlank=true);

// 3. Validate a role only when creating a new record
validatesInclusionOf(property=&quot;role&quot;, list=&quot;admin,editor,viewer&quot;, when=&quot;onCreate&quot;);

// 4. Validate a priority field only when a condition is met
validatesInclusionOf(property=&quot;priority&quot;, list=&quot;low,medium,high&quot;, condition=&quot;this.isAssigned()&quot;);
</code></pre>
