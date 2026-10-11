---
title: humanize()
description: "Returns readable text by capitalizing and converting camel casing to multiple words."
sidebar:
  label: humanize()
  order: 0
---

## Signature

`humanize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Returns readable text by capitalizing and converting camel casing to multiple words.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to humanize. |
| `except` | `string` | no | — | A list of strings (space separated) to replace within the output. |

</div>

## Examples

<pre><code class='javascript'>// 1. Humanize a camelCase string
result = humanize(&quot;wheelsIsAFramework&quot;);
// result -&gt; &quot;Wheels Is A Framework&quot;

// 2. Humanize a string and replace an abbreviation using the except argument
result = humanize(&quot;wheelsIsACfmlFramework&quot;, &quot;CFML&quot;);
// result -&gt; &quot;Wheels Is A CFML Framework&quot;

// 3. Humanize a multi-word property name from a model attribute
result = humanize(&quot;firstName&quot;);
// result -&gt; &quot;First Name&quot;
</code></pre>
