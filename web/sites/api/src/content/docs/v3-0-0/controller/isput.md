---
title: isPut()
description: "Checks whether the current HTTP request is a PUT request. PUT requests are typically used to update existing resources in RESTful APIs."
sidebar:
  label: isPut()
  order: 0
---

## Signature

`isPut()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks whether the current HTTP request is a PUT request. PUT requests are typically used to update existing resources in RESTful APIs.




## Examples

<pre><code class='javascript'>if (isPut()) {
    writeOutput(&quot;This request was submitted via PUT.&quot;);
} else {
    writeOutput(&quot;This request is not a PUT request.&quot;);
}</code></pre>
