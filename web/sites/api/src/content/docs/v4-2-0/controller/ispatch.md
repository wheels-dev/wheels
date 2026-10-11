---
title: isPatch()
description: "Returns whether the request was a <code>PATCH</code> request or not."
sidebar:
  label: isPatch()
  order: 0
---

## Signature

`isPatch()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request was a <code>PATCH</code> request or not.




## Examples

<pre><code class='javascript'>// 1. Only handle PATCH requests in an action
if (!isPatch()) {
    redirectTo(action = &quot;index&quot;);
}

// 2. Respond differently depending on whether the request is a PATCH
if (isPatch()) {
    // Apply a partial update to the resource
    user = model(&quot;User&quot;).findByKey(params.key);
    user.update(params.user);
} else {
    // Not a PATCH request; redirect away
    redirectTo(action = &quot;index&quot;);
}

// 3. Store the result to use in a conditional
requestIsPatch = isPatch();
// requestIsPatch -&gt; true for a PATCH request, false otherwise
</code></pre>
