---
title: titleize()
description: "Capitalizes all words in the text to create a nicer looking title."
sidebar:
  label: titleize()
  order: 0
---

## Signature

`titleize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Capitalizes all words in the text to create a nicer looking title.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The text to turn into a title. |

## Examples

<pre><code class='javascript'>&lt;!--- Will output: CFWheels Is A Framework For ColdFusion ---&gt;
#titleize(&quot;CFWheels is a framework for ColdFusion&quot;)#</code></pre>
