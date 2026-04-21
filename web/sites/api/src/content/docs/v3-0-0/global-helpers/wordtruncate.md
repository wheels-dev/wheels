---
title: wordTruncate()
description: "Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: wordTruncate()
  order: 0
---

## Signature

`wordTruncate()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
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

<pre><code class='javascript'>1. Basic truncation (default truncate string &quot;...&quot;)
wordTruncate(text=&quot;Wheels is a framework for ColdFusion&quot;, length=4)
// Output:
// Wheels is a framework...

2. Truncate with a custom string
wordTruncate(text=&quot;Wheels is a framework for ColdFusion&quot;, length=3, truncateString=&quot; (more)&quot;)
// Output:
// Wheels is a (more)

3. Using with shorter text than length (no truncation applied)
wordTruncate(text=&quot;Hello world&quot;, length=5)
// Output:
// Hello world

4. Dynamic usage in a view
&lt;cfoutput&gt;
    wordTruncate(text=post.content, length=10)
&lt;/cfoutput&gt;
// Useful for showing previews of long content while preserving word boundaries.
</code></pre>
