---
title: capitalize()
description: "Capitalizes the first character of the supplied string."
sidebar:
  label: capitalize()
  order: 0
---

## Signature

`capitalize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Capitalizes the first character of the supplied string.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | String to capitalize. |

</div>

## Examples

<pre><code class='javascript'>// 1. Capitalize the first character of a sentence
result = capitalize(&quot;wheels is a framework&quot;);
// result -&gt; &quot;Wheels is a framework&quot;

// 2. Capitalize a lowercase word
result = capitalize(&quot;hello&quot;);
// result -&gt; &quot;Hello&quot;

// 3. Returns an already-capitalized string unchanged
result = capitalize(&quot;CFWheels&quot;);
// result -&gt; &quot;CFWheels&quot;
</code></pre>
