---
title: compareTo()
description: "Compares the current model object with another model object to determine if they are effectively the same. This is useful for checking equality between two inst"
sidebar:
  label: compareTo()
  order: 0
---

## Signature

`compareTo()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Compares the current model object with another model object to determine if they are effectively the same. This is useful for checking equality between two instances of the same model before performing operations like updates or merges.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `object` | `component` | yes | — |  |

## Examples

<pre><code class='javascript'>1. Compare two user objects
user1 = model("user").findByKey(1);
user2 = model("user").findByKey(2);

if(user1.compareTo(user2)) {
    writeOutput("Objects are the same.");
} else {
    writeOutput("Objects are different.");
}

2. Compare dynamically after changing a property
user1 = model("user").findByKey(1);
user2 = model("user").findByKey(1);

user2.email = "[newemail@example.com](mailto:newemail@example.com)";

writeDump(user1.compareTo(user2)); // Will output false because email changed</code></pre>
