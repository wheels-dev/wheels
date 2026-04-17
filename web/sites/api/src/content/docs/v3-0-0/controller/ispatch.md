---
title: isPatch()
description: "Checks whether the current HTTP request was made using the PATCH method. Useful when building RESTful APIs where PATCH is used to partially update resources."
sidebar:
  label: isPatch()
  order: 0
---

## Signature

`isPatch()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Checks whether the current HTTP request was made using the PATCH method. Useful when building RESTful APIs where PATCH is used to partially update resources.




## Examples

<pre><code class='javascript'>&lt;cfscript&gt;
if (isPatch()) {
    writeOutput(&quot;This is a PATCH request.&quot;);
} else {
    writeOutput(&quot;This is a different type of request.&quot;);
}
&lt;/cfscript&gt;</code></pre>
