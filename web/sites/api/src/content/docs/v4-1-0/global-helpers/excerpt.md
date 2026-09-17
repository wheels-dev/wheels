---
title: excerpt()
description: "Extracts an excerpt from text that matches the first instance of a given phrase."
sidebar:
  label: excerpt()
  order: 0
---

## Signature

`excerpt()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Extracts an excerpt from text that matches the first instance of a given phrase.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to extract an excerpt from. |
| `phrase` | `string` | yes | — | The phrase to extract. |
| `radius` | `numeric` | no | `100` | Number of characters to extract surrounding the phrase. |
| `excerptString` | `string` | no | `...` | String to replace first and / or last characters with. |

</div>

## Examples

<pre><code class='javascript'>// 1. Extract text around a matching phrase with a custom radius
result = excerpt(text=&quot;CFWheels is a Rails-like MVC framework for Adobe ColdFusion and Lucee&quot;, phrase=&quot;framework&quot;, radius=5);
// result -&gt; &quot;...MVC framework for Ad...&quot;

// 2. Use the default radius of 100 characters
result = excerpt(text=&quot;CFWheels is a powerful MVC framework built for ColdFusion developers who want to move fast.&quot;, phrase=&quot;powerful&quot;);
// result -&gt; &quot;CFWheels is a powerful MVC framework built for ColdFusion developers who want to move fast.&quot;

// 3. Customize the excerpt string used to indicate truncated text
result = excerpt(text=&quot;The quick brown fox jumps over the lazy dog&quot;, phrase=&quot;fox&quot;, radius=5, excerptString=&quot; [...]&quot;);
// result -&gt; &quot; [...]brown fox jumps [...]&quot;
</code></pre>
