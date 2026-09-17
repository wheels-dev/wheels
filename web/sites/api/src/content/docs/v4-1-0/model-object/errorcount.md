---
title: errorCount()
description: "Returns the number of errors this object has associated with it."
sidebar:
  label: errorCount()
  order: 0
---

## Signature

`errorCount()` — returns `numeric`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns the number of errors this object has associated with it.
Specify property or name if you wish to count only specific errors.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Specify a property name here if you want to count only errors set on a specific property. |
| `name` | `string` | no | — | Specify an error name here if you want to count only errors set with a specific error name. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check the total number of errors on an object
if (author.errorCount() GTE 10) {
    // Too many errors — bail out early
}

// 2. Check how many errors are associated with a specific property
if (author.errorCount(property=&quot;email&quot;) gt 0) {
    // The email property has at least one error
}

// 3. Count errors that were set with a specific error name
count = author.errorCount(name=&quot;invalidFormat&quot;);
// count -&gt; 2 (two errors share the &quot;invalidFormat&quot; name)
</code></pre>
