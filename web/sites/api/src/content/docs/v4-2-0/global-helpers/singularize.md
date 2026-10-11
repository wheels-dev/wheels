---
title: singularize()
description: "Returns the singular form of the passed in word."
sidebar:
  label: singularize()
  order: 0
---

## Signature

`singularize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Returns the singular form of the passed in word.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The word to singularize. |

</div>

## Examples

<pre><code class='javascript'>// 1. Singularize a regular plural word
singular = singularize(&quot;languages&quot;);
// singular -&gt; &quot;language&quot;

// 2. Singularize an irregular plural
singular = singularize(&quot;children&quot;);
// singular -&gt; &quot;child&quot;

// 3. Singularize a camelCased word (only the last part is singularized)
singular = singularize(&quot;blogPosts&quot;);
// singular -&gt; &quot;blogPost&quot;
</code></pre>
