---
title: validatesPresenceOf()
description: "Validates that the specified property exists and that its value is not blank."
sidebar:
  label: validatesPresenceOf()
  order: 0
---

## Signature

`validatesPresenceOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the specified property exists and that its value is not blank.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] can't be empty` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>// 1. Require a single property (must exist and not be blank)
validatesPresenceOf(&quot;emailAddress&quot;);

// 2. Require multiple properties at once
validatesPresenceOf(properties=&quot;firstName,lastName,emailAddress&quot;);

// 3. Supply a custom error message
validatesPresenceOf(properties=&quot;title&quot;, message=&quot;A title is required.&quot;);

// 4. Only validate on create (skip when updating an existing record)
validatesPresenceOf(properties=&quot;password&quot;, when=&quot;onCreate&quot;);

// 5. Conditionally require a property based on another property value
validatesPresenceOf(properties=&quot;companyName&quot;, condition=&quot;this.accountType eq 'business'&quot;);

// 6. Skip validation when a certain condition is true
validatesPresenceOf(properties=&quot;bio&quot;, unless=&quot;this.isGuest()&quot;);
</code></pre>
