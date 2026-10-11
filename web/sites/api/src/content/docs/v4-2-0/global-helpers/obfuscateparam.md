---
title: obfuscateParam()
description: "Obfuscates a value. Typically used for hiding primary key values when passed along in the URL."
sidebar:
  label: obfuscateParam()
  order: 0
---

## Signature

`obfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Obfuscates a value. Typically used for hiding primary key values when passed along in the URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `any` | yes | — | The value to obfuscate. |

</div>

## Examples

<pre><code class='javascript'>// 1. Obfuscate a primary key value before including it in a URL
obfuscatedId = obfuscateParam(99);
// obfuscatedId -&gt; &quot;a3f6c1&quot; (an obfuscated hex string)

// 2. Use an obfuscated key in a generated URL to hide the real record ID
params.userKey = obfuscateParam(model(&quot;User&quot;).findOne().key());
redirectTo(route=&quot;userProfile&quot;, key=params.userKey);

// 3. Reverse the obfuscation with deobfuscateParam to get the original value back
obfuscated = obfuscateParam(42);
original = deobfuscateParam(obfuscated);
// original -&gt; &quot;42&quot;
</code></pre>
