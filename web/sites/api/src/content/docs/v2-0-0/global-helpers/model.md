---
title: model()
description: "Returns a reference to the requested model so that class level methods can be called on it."
sidebar:
  label: model()
  order: 0
---

## Signature

`model()` — returns `any`

**Available in:** `controller`, `model`, `migrator`
**Category:** Miscellaneous Functions

## Description

Returns a reference to the requested model so that class level methods can be called on it.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the model to get a reference to. |

</div>

## Examples

<pre>// The `model(&quot;author&quot;)` part of the code below gets a reference to the model from the application scope, and then the `findByKey` class level method is called on it
authorObject = model(&quot;author&quot;).findByKey(1);</pre>
