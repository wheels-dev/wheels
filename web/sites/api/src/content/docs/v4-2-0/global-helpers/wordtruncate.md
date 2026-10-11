---
title: wordTruncate()
description: "Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: wordTruncate()
  order: 0
---

## Signature

`wordTruncate()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to "...").



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | no | `5` | Number of words to truncate the text to. |
| `truncateString` | `string` | no | `...` | String to replace the last characters with. |

</div>

## Examples

<pre><code class='javascript'>// 1. Truncate text to the first 4 words (default truncate string &quot;...&quot;)
result = wordTruncate(text=&quot;CFWheels is a framework for ColdFusion&quot;, length=4);
// result -&gt; &quot;CFWheels is a framework...&quot;

// 2. Truncate with a custom truncate string
result = wordTruncate(text=&quot;The quick brown fox jumps over the lazy dog&quot;, length=5, truncateString=&quot; [read more]&quot;);
// result -&gt; &quot;The quick brown fox jumps [read more]&quot;

// 3. Text with fewer words than the limit is returned unchanged
result = wordTruncate(text=&quot;Short text&quot;, length=10);
// result -&gt; &quot;Short text&quot;
</code></pre>
