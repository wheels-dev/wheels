---
title: obfuscateParam()
description: "Obfuscates a value, typically used to hide sensitive information like primary key IDs when passing them in URLs. This helps prevent users from easily guessing s"
sidebar:
  label: obfuscateParam()
  order: 0
---

## Signature

`obfuscateParam()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Obfuscates a value, typically used to hide sensitive information like primary key IDs when passing them in URLs. This helps prevent users from easily guessing sequential IDs or sensitive values.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `param` | `any` | yes | — | The value to obfuscate. |

## Examples

<pre><code class='javascript'>1. Obfuscate a numeric primary key
// Primary key value
id = 99;

// Obfuscate it before sending in the URL
obfuscatedId = obfuscateParam(id);
writeOutput(obfuscatedId); 

2. Obfuscate a string value
// Obfuscate an email address
email = &quot;user@example.com&quot;;
obfuscatedEmail = obfuscateParam(email);
writeOutput(obfuscatedEmail); 

3. Use obfuscated value in a link
// Pass obfuscated ID in a linkTo helper
userId = 42;
#linkTo(text=&quot;View Profile&quot;, controller=&quot;user&quot;, action=&quot;profile&quot;, key=obfuscateParam(userId))#
</code></pre>
