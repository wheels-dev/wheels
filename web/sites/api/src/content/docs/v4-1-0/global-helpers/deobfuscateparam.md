---
title: deobfuscateParam()
description: "Deobfuscates a value."
sidebar:
  label: deobfuscateParam()
  order: 0
---

## Signature

`deobfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Deobfuscates a value.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `string` | yes | — | The value to deobfuscate. |

</div>

## Examples

<pre><code class='javascript'>// 1. Deobfuscate a URL parameter to get the original numeric ID
// (Wheels automatically obfuscates numeric URL params when obfuscateUrls is enabled)
originalId = deobfuscateParam(&quot;b7ab9a50&quot;);
// originalId -&gt; &quot;35&quot;

// 2. Round-trip: obfuscate a value, then deobfuscate it back
obfuscated = obfuscateParam(&quot;100&quot;);
original = deobfuscateParam(obfuscated);
// original -&gt; &quot;100&quot;

// 3. Non-obfuscated values (e.g. already plain integers) are returned as-is
passthrough = deobfuscateParam(&quot;42&quot;);
// passthrough -&gt; &quot;42&quot;
</code></pre>
