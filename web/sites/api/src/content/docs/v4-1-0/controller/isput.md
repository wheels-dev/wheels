---
title: isPut()
description: "Returns whether the request was a <code>PUT</code> request or not."
sidebar:
  label: isPut()
  order: 0
---

## Signature

`isPut()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request was a <code>PUT</code> request or not.




## Examples

<pre><code class='javascript'>// 1. Allow only PUT requests for a resource update action
if (!isPut()) {
    redirectTo(action = &quot;index&quot;);
}
// ... proceed with update logic

// 2. Branch behavior based on HTTP method
if (isPut()) {
    // Full replacement of the resource
    user = model(&quot;User&quot;).findByKey(params.key);
    user.update(params.user);
    redirectTo(action = &quot;show&quot;, key = user.key());
} else {
    renderNothing();
}
</code></pre>
