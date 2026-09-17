---
title: flash()
description: "Returns the value of a specific key in the Flash (or the entire Flash as a struct if no key is passed in)."
sidebar:
  label: flash()
  order: 0
---

## Signature

`flash()` — returns `any`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Returns the value of a specific key in the Flash (or the entire Flash as a struct if no key is passed in).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | no | — | The key to get the value for. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the current value of a specific key in the Flash
notice = flash(&quot;notice&quot;);
// notice -&gt; &quot;Your profile was updated successfully.&quot;

// 2. Get the entire Flash as a struct when no key is passed
flashContents = flash();
// flashContents -&gt; {notice: &quot;Record saved.&quot;, error: &quot;Something went wrong.&quot;}

// 3. Check for a key before reading it to avoid an empty-string fallback
if (flashKeyExists(&quot;error&quot;)) {
    errorMessage = flash(&quot;error&quot;);
}
</code></pre>
