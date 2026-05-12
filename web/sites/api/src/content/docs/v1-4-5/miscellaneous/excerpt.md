---
title: excerpt()
description: "Extracts an excerpt from text that matches the first instance of a given phrase."
sidebar:
  label: excerpt()
  order: 0
---

## Signature

`excerpt()` — returns `any`




## Description

Extracts an excerpt from text that matches the first instance of a given phrase.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to extract an excerpt from. |
| `phrase` | `string` | yes | — | The phrase to extract. |
| `radius` | `numeric` | yes | `100` | Number of characters to extract surrounding the phrase. |
| `excerptString` | `string` | yes | `...` | String to replace first and/or last characters with. |

</div>

## Examples

<pre>#excerpt(text=&quot;ColdFusion CFWheels is a Rails-like MVC framework for Adobe ColdFusion, Railo and Lucee&quot;, phrase=&quot;framework&quot;, radius=5)#
-&gt; ... MVC framework for ...</pre>
