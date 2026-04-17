---
title: flashInsert()
description: "The flashInsert() function adds a new key-value pair to the Flash scope. This is useful for storing temporary messages or data that you want to persist across t"
sidebar:
  label: flashInsert()
  order: 0
---

## Signature

`flashInsert()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashInsert() function adds a new key-value pair to the Flash scope. This is useful for storing temporary messages or data that you want to persist across the next request, typically after a redirect. You can insert any type of value, such as strings, numbers, or structs, and later retrieve it using flash().




## Examples

<pre><code class='javascript'>1. Insert a simple flash message
flashInsert(msg=&quot;It Worked!&quot;);

2. Insert multiple types of data
flashInsert(userId=123);
flashInsert(errorMessage=&quot;Something went wrong&quot;);

3. Typical usage: insert a message before redirecting
flashInsert(notice=&quot;Profile updated successfully&quot;);
redirectTo(action=&quot;show&quot;);

4. Insert a structured value
flashInsert(userStruct={id=42, name=&quot;Alice&quot;});
</code></pre>
