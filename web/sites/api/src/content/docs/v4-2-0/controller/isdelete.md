---
title: isDelete()
description: "Returns whether the request was a <code>DELETE</code> request or not."
sidebar:
  label: isDelete()
  order: 0
---

## Signature

`isDelete()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns whether the request was a <code>DELETE</code> request or not.




## Examples

<pre><code class='javascript'>// 1. Only process delete logic when the request method is DELETE
if (isDelete()) {
    // perform delete operation
}

// 2. Assign the result to a variable for later use
requestIsDelete = isDelete();
</code></pre>
