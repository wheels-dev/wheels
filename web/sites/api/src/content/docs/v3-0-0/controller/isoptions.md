---
title: isOptions()
description: "Checks whether the current HTTP request was made using the OPTIONS method. Useful in REST APIs or CORS preflight requests."
sidebar:
  label: isOptions()
  order: 0
---

## Signature

`isOptions()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks whether the current HTTP request was made using the OPTIONS method. Useful in REST APIs or CORS preflight requests.




## Examples

<pre><code class='javascript'>&lt;cfscript&gt;
if (isOptions()) {
   // Handle CORS preflight or respond to OPTIONS request
   writeOutput(&quot;This is an OPTIONS request.&quot;);
} else {
   writeOutput(&quot;This is a different type of request.&quot;);
}
&lt;/cfscript&gt;</code></pre>
