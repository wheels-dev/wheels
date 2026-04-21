---
title: titleize()
description: "Converts a string so that the first letter of each word is capitalized, producing a cleaner, title-like appearance. It is useful for formatting headings, labels"
sidebar:
  label: titleize()
  order: 0
---

## Signature

`titleize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Converts a string so that the first letter of each word is capitalized, producing a cleaner, title-like appearance. It is useful for formatting headings, labels, or any text that should follow title case conventions.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The text to turn into a title. |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage
titleize("Wheels is a framework for ColdFusion")
// Output: "Wheels Is A Framework For ColdFusion"

2. Works with single words
titleize("hello")
// Output: "Hello"

3. Works with multiple words including numbers
titleize("coldfusion 2025 features")
// Output: "Coldfusion 2025 Features"

4. Can be used in views for dynamic labels
&lt;h1&gt;titleize(article.title)&lt;/h1&gt;</code></pre>
