---
title: set()
description: "Use to configure a global setting or set a default for a function."
sidebar:
  label: set()
  order: 0
---

## Signature

`set()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Use to configure a global setting or set a default for a function.




## Examples

<pre><code class='javascript'>// 1. Set the `URLRewriting` global setting to `Partial`.
set(URLRewriting=&quot;Partial&quot;);

// 2. Set default argument values for the `buttonTo` view helper.
// This pattern works for most Wheels helper functions and their arguments.
set(functionName=&quot;buttonTo&quot;, onlyPath=true, host=&quot;&quot;, protocol=&quot;&quot;, port=0, text=&quot;&quot;, confirm=&quot;&quot;, image=&quot;&quot;, disable=&quot;&quot;);

// 3. Set default values for the `textField` form helper to control label placement and wrapping markup.
set(functionName=&quot;textField&quot;, labelPlacement=&quot;before&quot;, prependToLabel=&quot;&lt;div&gt;&quot;, append=&quot;&lt;/div&gt;&quot;, appendToLabel=&quot;&lt;br&gt;&quot;);

// 4. Apply the same defaults to multiple helper functions at once by passing a comma-delimited list to `functionName`.
set(functionName=&quot;textField,passwordField,textArea&quot;, labelPlacement=&quot;before&quot;);
</code></pre>
