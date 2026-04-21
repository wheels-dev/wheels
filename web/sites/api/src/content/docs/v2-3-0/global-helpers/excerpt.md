---
title: excerpt()
description: "Extracts an excerpt from text that matches the first instance of a given phrase."
sidebar:
  label: excerpt()
  order: 0
---

## Signature

`excerpt()` — returns `string`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
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

<pre><code class='javascript'>&lt;!--- Will output: ... MVC framework for ... ---&gt;
#excerpt(text=&quot;CFWheels is a Rails-like MVC framework for Adobe ColdFusion and Lucee&quot;, phrase=&quot;framework&quot;, radius=5)#</code></pre>
