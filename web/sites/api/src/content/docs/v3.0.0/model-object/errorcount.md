---
title: errorCount()
description: "Returns the number of errors this object has associated with it."
sidebar:
  label: errorCount()
  order: 0
---

## Signature

`errorCount()` — returns `numeric`

**Available in:** `model`
**Category:** Error Functions

## Description

Returns the number of errors this object has associated with it.
Specify property or name if you wish to count only specific errors.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Specify a property name here if you want to count only errors set on a specific property. |
| `name` | `string` | no | — | Specify an error name here if you want to count only errors set with a specific error name. |

## Examples

<pre><code class='javascript'>1. Check how many errors are set on the object
if(author.errorCount() GTE 10){
    // Do something to deal with this very erroneous author here...
}

2. Check how many errors are associated with the `email` property
if(author.errorCount(&quot;email&quot;) gt 0){
    // Do something to deal with this erroneous author here...
}

3. Count errors by error name
if (author.errorCount("", "invalidFormat") GT 0) {
    // Handle errors with a specific error name
    writeOutput("There are fields with invalid formatting!");
}</code></pre>
