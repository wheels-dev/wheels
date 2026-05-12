---
title: excerpt()
description: "excerpt() extracts a portion of text surrounding the first instance of a given phrase. This is useful for previews, search result snippets, or highlighting cont"
sidebar:
  label: excerpt()
  order: 0
---

## Signature

`excerpt()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

excerpt() extracts a portion of text surrounding the first instance of a given phrase. This is useful for previews, search result snippets, or highlighting context around a keyword.



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

<pre><code class='javascript'>Example 1 — Basic usage
&lt;cfscript&gt;
text = &quot;Wheels is a Rails-like MVC framework for Adobe ColdFusion and Lucee&quot;;

snippet = excerpt(text=text, phrase=&quot;framework&quot;, radius=5);

writeOutput(snippet);
&lt;/cfscript&gt;

Output:

... MVC framework for ...

Extracts 5 characters before and after &quot;framework&quot;.

Adds ... at the start and end to indicate truncation.

Example 2 — Increase radius
&lt;cfscript&gt;
snippet = excerpt(text=text, phrase=&quot;framework&quot;, radius=20);

writeOutput(snippet);
&lt;/cfscript&gt;

Output:

... Rails-like MVC framework for Adobe Cold...

Shows more surrounding context (20 characters before and after the phrase).

Example 3 — Custom excerpt string
&lt;cfscript&gt;
snippet = excerpt(
 text=text,
 phrase=&quot;framework&quot;,
 radius=10,
 excerptString=&quot;***&quot;
);

writeOutput(snippet);
&lt;/cfscript&gt;

Output:

*** Rails-like MVC framework for Adob ***

Uses *** instead of ... to mark truncated text.
</code></pre>
