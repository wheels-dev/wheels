---
title: pluralize()
description: "Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the <code>count</code> argument. Wheels stores a list of wor"
sidebar:
  label: pluralize()
  order: 0
---

## Signature

`pluralize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
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

<pre><code class='javascript'>1. Basic pluralization
pluralize(&quot;person&quot;)
&lt;!--- Returns: &quot;people&quot; ---&gt;

2. Pluralization with count (count = 1, so singular is returned)
pluralize(word=&quot;car&quot;, count=1)
&lt;!--- Returns: &quot;1 car&quot; ---&gt;

3. Pluralization with count (count = 5, so plural is returned)
pluralize(word=&quot;car&quot;, count=5)
&lt;!--- Returns: &quot;5 cars&quot; ---&gt;

4. Suppressing the count in the result
pluralize(word=&quot;dog&quot;, count=3, returnCount=false)
&lt;!--- Returns: &quot;dogs&quot; ---&gt;

5. Irregular plural (child → children)
pluralize(&quot;child&quot;)
&lt;!--- Returns: &quot;children&quot; ---&gt;

6. Uncountable word stays the same
pluralize(&quot;equipment&quot;)
&lt;!--- Returns: &quot;equipment&quot; ---&gt;

7. With count and uncountable word
pluralize(word=&quot;equipment&quot;, count=2)
&lt;!--- Returns: &quot;2 equipment&quot; ---&gt;
</code></pre>
