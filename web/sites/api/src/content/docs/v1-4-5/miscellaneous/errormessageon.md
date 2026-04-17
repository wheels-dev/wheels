---
title: errorMessageOn()
description: "Returns the error message, if one exists, on the object's property. If multiple error messages exist, the first one is returned."
sidebar:
  label: errorMessageOn()
  order: 0
---

## Signature

`errorMessageOn()` — returns `any`




## Description

Returns the error message, if one exists, on the object's property. If multiple error messages exist, the first one is returned.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | The variable name of the object to display the error message for. |
| `property` | `string` | yes | — | The name of the property to display the error message for. |
| `prependText` | `string` | yes | — | String to prepend to the error message. |
| `appendText` | `string` | yes | — | String to append to the error message. |
| `wrapperElement` | `string` | yes | `span` | HTML element to wrap the error message in. |
| `class` | `string` | yes | `errorMessage` | CSS class to set on the wrapper element. |

## Examples

<pre>errorMessageOn(objectName, property [, prependText, appendText, wrapperElement, class ]) &lt;!--- view code ---&gt;
&lt;cfoutput&gt;
  #errorMessageOn(objectName=&quot;user&quot;, property=&quot;email&quot;)#
&lt;/cfoutput&gt;</pre>
