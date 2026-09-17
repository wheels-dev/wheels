---
title: flashDelete()
description: "Deletes a specific key from the Flash."
sidebar:
  label: flashDelete()
  order: 0
---

## Signature

`flashDelete()` — returns `any`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Deletes a specific key from the Flash.
Returns <code>true</code> if the key exists.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | yes | — | The key to delete |

</div>

## Examples

<pre><code class='javascript'>// 1. Delete a key from the Flash
flashDelete(key=&quot;errorMessage&quot;);

// 2. Check the return value — true if the key existed, false if it did not
wasPresent = flashDelete(key=&quot;notice&quot;);
// wasPresent -&gt; true  (key existed and was removed)
// wasPresent -&gt; false (key did not exist in the Flash)

// 3. Conditionally act on whether the key was actually removed
if (flashDelete(key=&quot;warning&quot;)) {
    // key existed; it has now been removed from the Flash
} else {
    // key was not present; nothing was changed
}
</code></pre>
