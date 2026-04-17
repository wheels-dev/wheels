---
title: set()
description: "Used to configure global settings or set default argument values for Wheels functions. It can be applied to core functions, helpers, and even migrations. This a"
sidebar:
  label: set()
  order: 0
---

## Signature

`set()` — returns `void`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Used to configure global settings or set default argument values for Wheels functions. It can be applied to core functions, helpers, and even migrations. This allows you to define a standard behavior across your application without repeating arguments every time a function is called.




## Examples

<pre><code class='javascript'>1. Set the `URLRewriting` setting to `Partial`.
set(URLRewriting=&quot;Partial&quot;);

2. Set default values for the arguments in the `buttonTo` view helper. This works for the majority of Wheels functions/arguments.
set(functionName=&quot;buttonTo&quot;, onlyPath=true, host=&quot;&quot;, protocol=&quot;&quot;, port=0, text=&quot;&quot;, confirm=&quot;&quot;, image=&quot;&quot;, disable=&quot;&quot;);

3. Set the default values for a form helper to get the form marked up to your preferences.
set(functionName=&quot;textField&quot;, labelPlacement=&quot;before&quot;, prependToLabel=&quot;&lt;div&gt;&quot;, append=&quot;&lt;/div&gt;&quot;, appendToLabel=&quot;&lt;br&gt;&quot;):
</code></pre>
