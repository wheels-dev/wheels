---
title: capitalize()
description: "Capitalizes the first letter of every word in the provided text, creating a nicely formatted title or sentence."
sidebar:
  label: capitalize()
  order: 0
---

## Signature

`capitalize()` — returns `string`

**Available in:** `controller`, `model`, `test`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Capitalizes the first letter of every word in the provided text, creating a nicely formatted title or sentence.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Capitalize a single sentence
#capitalize("wheels is a framework")#
<!--- Output: Wheels Is A Framework --->

2. Capitalize a name
#capitalize("john doe")#
<!--- Output: John Doe --->

3. Capitalize a title
#capitalize("introduction to wheels framework")#
<!--- Output: Introduction To Wheels Framework ---></code></pre>
