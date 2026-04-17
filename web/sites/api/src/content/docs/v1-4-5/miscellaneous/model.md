---
title: model()
description: "Returns a reference to the requested model so that class level methods can be called on it."
sidebar:
  label: model()
  order: 0
---

## Signature

`model()` — returns `any`




## Description

Returns a reference to the requested model so that class level methods can be called on it.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the model to get a reference to. |

## Examples

<pre>model(name) &lt;!--- The `model(&quot;author&quot;)` part of the code below gets a reference to the model from the application scope, and then the `findByKey` class level method is called on it ---&gt;
&lt;cfset authorObject = model(&quot;author&quot;).findByKey(1)&gt;</pre>
