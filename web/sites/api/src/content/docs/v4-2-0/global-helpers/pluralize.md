---
title: pluralize()
description: "Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the <code>count</code> argument. Wheels stores a list of wor"
sidebar:
  label: pluralize()
  order: 0
---

## Signature

`pluralize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the <code>count</code> argument. Wheels stores a list of words that are the same in both singular and plural form (e.g. "equipment", "information") and words that don't follow the regular pluralization rules (e.g. "child" / "children", "foot" / "feet"). Use <code>get("uncountables")</code> / <code>set("uncountables", newList)</code> and <code>get("irregulars")</code> / <code>set("irregulars", newList)</code> to modify them to suit your needs.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The word to pluralize. |
| `count` | `numeric` | no | `-1` | Pluralization will occur when this value is not 1. |
| `returnCount` | `boolean` | no | `true` | Will return count prepended to the pluralization when true and count is not -1. |

</div>

## Examples

<pre><code class='javascript'>// 1. Pluralize a word using standard rules
writeOutput(pluralize(&quot;person&quot;));
// -&gt; &quot;people&quot;

// 2. Pluralize based on a count; returns count prepended to the word
writeOutput(pluralize(word=&quot;comment&quot;, count=1));
// -&gt; &quot;1 comment&quot;

writeOutput(pluralize(word=&quot;comment&quot;, count=5));
// -&gt; &quot;5 comments&quot;

// 3. Pluralize based on a count but omit the count from the output
writeOutput(pluralize(word=&quot;person&quot;, count=users.RecordCount, returnCount=false));
// -&gt; &quot;people&quot; (when RecordCount != 1) or &quot;person&quot; (when RecordCount == 1)
</code></pre>
