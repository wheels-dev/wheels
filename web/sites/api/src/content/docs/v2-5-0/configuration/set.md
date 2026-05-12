---
title: set()
description: "Use to configure a global setting or set a default for a function."
sidebar:
  label: set()
  order: 0
---

## Signature

`set()` — returns `void`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Use to configure a global setting or set a default for a function.




## Examples

<pre><code class='javascript'>// Example 1: Set the `URLRewriting` setting to `Partial`.
set(URLRewriting=&quot;Partial&quot;);

// Example 2: Set default values for the arguments in the `buttonTo` view helper. This works for the majority of Wheels functions/arguments.
set(functionName=&quot;buttonTo&quot;, onlyPath=true, host=&quot;&quot;, protocol=&quot;&quot;, port=0, text=&quot;&quot;, confirm=&quot;&quot;, image=&quot;&quot;, disable=&quot;&quot;);

// Example 3: Set the default values for a form helper to get the form marked up to your preferences.
set(functionName=&quot;textField&quot;, labelPlacement=&quot;before&quot;, prependToLabel=&quot;&lt;div&gt;&quot;, append=&quot;&lt;/div&gt;&quot;, appendToLabel=&quot;&lt;br&gt;&quot;):
</code></pre>
