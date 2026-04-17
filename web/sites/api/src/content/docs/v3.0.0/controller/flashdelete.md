---
title: flashDelete()
description: "The flashDelete() function removes a specific key from the Flash scope. It is useful when you want to delete a particular temporary message or piece of data wit"
sidebar:
  label: flashDelete()
  order: 0
---

## Signature

`flashDelete()` — returns `any`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashDelete() function removes a specific key from the Flash scope. It is useful when you want to delete a particular temporary message or piece of data without clearing the entire Flash. The function returns true if the key existed and was deleted, or false if the key was not present.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | yes | — | The key to delete |

## Examples

<pre><code class='javascript'>1. Delete a single flash message
flashDelete(key=&quot;errorMessage&quot;);

2. Delete another key and check if it existed
if (flashDelete(key=&quot;notice&quot;)) {
    writeOutput(&quot;Notice deleted from Flash.&quot;);
} else {
    writeOutput(&quot;Notice key did not exist.&quot;);
}

3. Conditional usage before displaying flash
if (structKeyExists(flash(), &quot;warning&quot;)) {
    warningMsg = flash(&quot;warning&quot;);
    flashDelete(key=&quot;warning&quot;); // remove after reading
    writeOutput(warningMsg);
}
</code></pre>
