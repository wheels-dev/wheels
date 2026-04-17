---
title: humanize()
description: "Converts a camel-cased or underscored string into more readable, human-friendly text by inserting spaces and capitalizing words. You can also specify words that"
sidebar:
  label: humanize()
  order: 0
---

## Signature

`humanize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Converts a camel-cased or underscored string into more readable, human-friendly text by inserting spaces and capitalizing words. You can also specify words that should be replaced or kept in a specific format.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | Text to humanize. |
| `except` | `string` | no | — | A list of strings (space separated) to replace within the output. |

## Examples

<pre><code class='javascript'>1. Humanize a string, will result in &quot;Wheels Is A Framework&quot;
#humanize(text=&quot;wheelsIsAFramework&quot;)#

2.Humanize a string, force wheels to replace &quot;Cfml&quot; with &quot;CFML&quot;
#humanize(text=&quot;wheelsIsACfmlFramework&quot;, except=&quot;CFML&quot;)#</code></pre>
