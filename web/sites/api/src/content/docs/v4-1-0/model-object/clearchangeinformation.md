---
title: clearChangeInformation()
description: "Clears all internal knowledge of the current state of the object."
sidebar:
  label: clearChangeInformation()
  order: 0
---

## Signature

`clearChangeInformation()` — returns `void`

**Available in:** `model`
**Category:** Change Functions

## Description

Clears all internal knowledge of the current state of the object.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | string false Name of property to clear information for. |

</div>

## Examples

<pre><code class='javascript'>// 1. Clear change tracking for a single property
// Convert startTime to UTC in an afterFind callback, then tell Wheels to treat
// the converted value as the &quot;original&quot; so it won't be flagged as changed or
// saved unnecessarily.
this.startTime = dateConvert(&quot;Local2UTC&quot;, this.startTime);
this.clearChangeInformation(property=&quot;startTime&quot;);

// 2. Clear change tracking for all properties at once
// After manually adjusting values in an afterFind callback, reset Wheels'
// internal state so none of the touched properties appear as dirty.
this.clearChangeInformation();

// 3. Typical afterFind callback usage in a model
// In User.cfc config():
//   afterFind(&quot;normalizeTimestamps&quot;);
// The callback method:
function normalizeTimestamps() {
    if (structKeyExists(this, &quot;createdAt&quot;)) {
        this.createdAt = dateConvert(&quot;Local2UTC&quot;, this.createdAt);
    }
    if (structKeyExists(this, &quot;updatedAt&quot;)) {
        this.updatedAt = dateConvert(&quot;Local2UTC&quot;, this.updatedAt);
    }
    // Mark both properties as clean so hasChanged() returns false
    // and save() won't push them back to the database.
    this.clearChangeInformation(property=&quot;createdAt&quot;);
    this.clearChangeInformation(property=&quot;updatedAt&quot;);
}
</code></pre>
