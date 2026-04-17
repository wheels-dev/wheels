---
title: deobfuscateParam()
description: "Deobfuscates a value."
sidebar:
  label: deobfuscateParam()
  order: 0
---

## Signature

`deobfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Deobfuscates a value.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `string` | yes | — | The value to deobfuscate. |

## Examples

<pre><code class='javascript'>// Get the original value from an obfuscated one
originalValue = deobfuscateParam(&quot;b7ab9a50&quot;);</code></pre>
