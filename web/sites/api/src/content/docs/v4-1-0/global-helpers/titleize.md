---
title: titleize()
description: "Capitalizes all words in the text to create a nicer looking title."
sidebar:
  label: titleize()
  order: 0
---

## Signature

`titleize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Capitalizes all words in the text to create a nicer looking title.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The text to turn into a title. |

</div>

## Examples

<pre><code class='javascript'>// 1. Capitalize each word in a plain sentence
result = titleize(&quot;the quick brown fox&quot;);
// result -&gt; &quot;The Quick Brown Fox&quot;

// 2. Capitalize a page title that is already mixed case
result = titleize(&quot;CFWheels is a framework for ColdFusion&quot;);
// result -&gt; &quot;CFWheels Is A Framework For ColdFusion&quot;

// 3. Use titleize to format a record name for display
article = model(&quot;Article&quot;).findByKey(params.key);
writeOutput(titleize(article.title));
</code></pre>
