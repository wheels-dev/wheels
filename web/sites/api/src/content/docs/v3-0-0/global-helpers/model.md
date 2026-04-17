---
title: model()
description: "Returns a reference to a specific model defined in your application, allowing you to call class-level methods on it. This is useful when you want to access data"
sidebar:
  label: model()
  order: 0
---

## Signature

`model()` — returns `any`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns a reference to a specific model defined in your application, allowing you to call class-level methods on it. This is useful when you want to access database records or invoke model methods without instantiating a new object first.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the model to get a reference to. |

## Examples

<pre><code class='javascript'>// The `model(&quot;author&quot;)` part of the code below gets a reference to the model from the application scope, and then the `findByKey` class level method is called on it
authorObject = model(&quot;author&quot;).findByKey(1);</code></pre>
