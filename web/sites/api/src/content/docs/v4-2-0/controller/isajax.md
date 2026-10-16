---
title: isAjax()
description: "Returns whether the page was called from JavaScript or not."
sidebar:
  label: isAjax()
  order: 0
---

## Signature

`isAjax()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the page was called from JavaScript or not.




## Examples

<pre><code class='javascript'>// 1. Respond differently based on whether the request is an AJAX call
if (isAjax()) {
    renderNothing();
} else {
    redirectTo(action = &quot;index&quot;);
}

// 2. Return JSON for AJAX requests, render a full view otherwise
if (isAjax()) {
    renderWith(data = model(&quot;Article&quot;).findAll(returnAs = &quot;objects&quot;));
} else {
    articles = model(&quot;Article&quot;).findAll();
}
</code></pre>
