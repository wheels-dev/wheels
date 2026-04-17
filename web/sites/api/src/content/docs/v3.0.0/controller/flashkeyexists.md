---
title: flashKeyExists()
description: "The flashKeyExists() function checks whether a specific key is present in the Flash scope. It returns true if the key exists and false if it does not. This is u"
sidebar:
  label: flashKeyExists()
  order: 0
---

## Signature

`flashKeyExists()` — returns `boolean`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashKeyExists() function checks whether a specific key is present in the Flash scope. It returns true if the key exists and false if it does not. This is useful for conditionally displaying or processing Flash messages or data before attempting to read them.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | yes | — | The key to check. |

## Examples

<pre><code class='javascript'>1. Check if the &quot;error&quot; key exists
errorExists = flashKeyExists(&quot;error&quot;);

2. Conditional display based on key existence
if (flashKeyExists(&quot;notice&quot;)) {
    writeOutput(flash(&quot;notice&quot;));
}

3. Example usage in a form flow
if (flashKeyExists(&quot;validationErrors&quot;)) {
    errors = flash(&quot;validationErrors&quot;);
    // Process or display errors
}
</code></pre>
