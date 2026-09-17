---
title: hasErrors()
description: "Returns <code>true</code> if the object has any errors."
sidebar:
  label: hasErrors()
  order: 0
---

## Signature

`hasErrors()` — returns `boolean`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns <code>true</code> if the object has any errors.
You can also limit to only check a specific property or name for errors.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to check if there are any errors set on. |
| `name` | `string` | no | — | Error name to check if there are any errors set with. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check if a post object has any errors at all
if (post.hasErrors()) {
    // Redirect user back to the form to correct errors
}

// 2. Check if a specific property has errors
if (post.hasErrors(property=&quot;title&quot;)) {
    // The title field has at least one error
}

// 3. Check if any errors were set with a specific name
if (post.hasErrors(name=&quot;uniquenessViolation&quot;)) {
    // Handle uniqueness error specifically
}
</code></pre>
