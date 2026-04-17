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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to humanize. |
| `except` | `string` | no | — | A list of strings (space separated) to replace within the output. |

## Examples

<pre><code class='javascript'>&lt;!--- Humanize a string, will result in &quot;Wheels Is A Framework&quot; ---&gt;
#humanize(&quot;wheelsIsAFramework&quot;)#

&lt;!--- Humanize a string, force wheels to replace &quot;Cfml&quot; with &quot;CFML&quot; ---&gt;
#humanize(&quot;wheelsIsACfmlFramework&quot;, &quot;CFML&quot;)#</code></pre>
