---
title: pluralize()
description: "Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the <code>count</code> argument. CFWheels stores a list of w"
sidebar:
  label: pluralize()
  order: 0
---

## Signature

`pluralize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`
**Category:** String Functions

## Description

Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the <code>count</code> argument. CFWheels stores a list of words that are the same in both singular and plural form (e.g. "equipment", "information") and words that don't follow the regular pluralization rules (e.g. "child" / "children", "foot" / "feet"). Use <code>get("uncountables")</code> / <code>set("uncountables", newList)</code> and <code>get("irregulars")</code> / <code>set("irregulars", newList)</code> to modify them to suit your needs.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The word to pluralize. |
| `count` | `numeric` | no | `-1` | Pluralization will occur when this value is not 1. |
| `returnCount` | `boolean` | no | `true` | Will return count prepended to the pluralization when true and count is not -1. |

</div>

## Examples

<pre>// Pluralize a word, will result in &quot;people&quot; 
#pluralize(&quot;person&quot;)#

// Pluralize based on the count passed in 
Your search returned #pluralize(word=&quot;person&quot;, count=users.RecordCount)#</pre>
