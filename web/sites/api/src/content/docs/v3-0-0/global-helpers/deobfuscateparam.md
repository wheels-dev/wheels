---
title: deobfuscateParam()
description: "Converts an obfuscated string back into its original value. This is typically used when IDs or other sensitive data are encoded for security purposes and need t"
sidebar:
  label: deobfuscateParam()
  order: 0
---

## Signature

`deobfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Converts an obfuscated string back into its original value. This is typically used when IDs or other sensitive data are encoded for security purposes and need to be restored to their original form.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `string` | yes | — | The value to deobfuscate. |

</div>

## Examples

<pre><code class='javascript'>Example 1: Deobfuscate a single value
&lt;cfscript&gt;
// Assume "b7ab9a50" is an obfuscated ID
originalValue = deobfuscateParam("b7ab9a50");

writeOutput("Original value: #originalValue#");
&lt;/cfscript&gt;

Converts the obfuscated string "b7ab9a50" back to its original value.

Useful for safely passing IDs in URLs or forms while preventing direct exposure of database keys.

Example 2: Deobfuscate a request parameter
&lt;cfscript&gt;
// Assume params.userId contains an obfuscated user ID
userId = deobfuscateParam(params.userId);

user = model("user").findByKey(userId);
writeDump(user);
&lt;/cfscript&gt;

Safely retrieves a user using an obfuscated ID passed in a URL or form.</code></pre>
