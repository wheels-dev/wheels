---
title: accessibleProperties()
description: "Use this method to specify which properties can be set through mass assignment."
sidebar:
  label: accessibleProperties()
  order: 0
---

## Signature

`accessibleProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to specify which properties can be set through mass assignment.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Property name (or list of property names) that are allowed to be altered through mass assignment. |

</div>

## Examples

<pre><code class='javascript'>// Mass assignment is open by default: with neither accessibleProperties() nor
// protectedProperties(), every property can be set via new() / create() / update().
// set(massAssignmentStrict=true) fail-closes that case (opt-in; not the default).

// 1. Allow only `isActive` to be set through mass assignment (e.g. `updateAll()`, `new()`, `update()`).
config() {
	accessibleProperties(&quot;isActive&quot;);
}

// 2. Allow a comma-delimited list of properties to be set through mass assignment.
//    Any property not in this list is silently ignored when set via mass assignment.
config() {
	accessibleProperties(&quot;firstName,lastName,email&quot;);
}
</code></pre>
