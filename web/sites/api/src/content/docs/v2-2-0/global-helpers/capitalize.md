---
title: capitalize()
description: "Capitalizes all words in the text to create a nicer looking title."
sidebar:
  label: capitalize()
  order: 0
---

## Signature

`capitalize()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Capitalizes all words in the text to create a nicer looking title.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — |  |

</div>

## Examples

<pre><code class='javascript'>&lt;!--- Capitalize a sentence, will result in &quot;Wheels is a framework&quot;---&gt;
#capitalize(&quot;wheels is a framework&quot;)#</code></pre>
