---
title: protectedProperties()
description: "Use this method to specify which properties cannot be set through mass assignment."
sidebar:
  label: protectedProperties()
  order: 0
---

## Signature

`protectedProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to specify which properties cannot be set through mass assignment.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Property name (or list of property names) that are not allowed to be altered through mass assignment. |

</div>

## Examples

<pre><code class='javascript'>// Without accessibleProperties() or protectedProperties(), mass assignment is open.
// set(massAssignmentStrict=true) fail-closes that case (opt-in; not the default).

// 1. Protect a comma-delimited list of properties from mass assignment in `models/User.cfc`.
// `firstName` and `lastName` cannot be changed via `updateAll()`, `new()`, `update()`, etc.
function config() {
	protectedProperties(&quot;firstName,lastName&quot;);
}

// 2. Using the named argument form to protect sensitive fields like `role` and `isAdmin`
function config() {
	protectedProperties(properties=&quot;role,isAdmin&quot;);
}
</code></pre>
