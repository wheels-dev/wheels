---
title: get()
description: "Returns the current setting for the supplied Wheels setting or the current default for the supplied Wheels function argument."
sidebar:
  label: get()
  order: 0
---

## Signature

`get()` — returns `any`




## Description

Returns the current setting for the supplied Wheels setting or the current default for the supplied Wheels function argument.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Variable name to get setting for. |
| `functionName` | `string` | yes | — | Function name to get setting for. |

## Examples

<pre>get(name [, functionName ]) &lt;!--- Get the current value for the `tableNamePrefix` Wheels setting ---&gt;
&lt;cfset setting = get(&quot;tableNamePrefix&quot;)&gt;

&lt;!--- Get the default for the `message` argument of the `validatesConfirmationOf` method  ---&gt;
&lt;cfset setting = get(functionName=&quot;validatesConfirmationOf&quot;, name=&quot;message&quot;)&gt;</pre>
