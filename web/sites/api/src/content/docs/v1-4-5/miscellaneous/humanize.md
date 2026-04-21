---
title: humanize()
description: "Returns readable text by capitalizing and converting camel casing to multiple words."
sidebar:
  label: humanize()
  order: 0
---

## Signature

`humanize()` — returns `any`




## Description

Returns readable text by capitalizing and converting camel casing to multiple words.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to humanize. |
| `except` | `string` | yes | — | a list of strings (space separated) to replace within the output. |

</div>

## Examples

<pre>humanize(text [, except ]) &lt;!--- Humanize a string, will result in &quot;Wheels Is A Framework&quot; ---&gt;
#humanize(&quot;wheelsIsAFramework&quot;)#

&lt;!--- Humanize a string, force wheels to replace &quot;Cfml&quot; with &quot;CFML&quot; ---&gt;
#humanize(&quot;wheelsIsACFMLFramework&quot;, &quot;CFML&quot;)#</pre>
