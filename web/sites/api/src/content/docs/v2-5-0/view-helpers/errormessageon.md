---
title: errorMessageOn()
description: "Returns the error message, if one exists, on the object's property."
sidebar:
  label: errorMessageOn()
  order: 0
---

## Signature

`errorMessageOn()` — returns `string`

**Available in:** `controller`
**Category:** Error Functions

## Description

Returns the error message, if one exists, on the object's property.
If multiple error messages exist, the first one is returned.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | The variable name of the object to display the error message for. |
| `property` | `string` | yes | — | The name of the property to display the error message for. |
| `prependText` | `string` | no | — | String to prepend to the error message. |
| `appendText` | `string` | no | — | String to append to the error message. |
| `wrapperElement` | `string` | no | `span` | HTML element to wrap the error message in. |
| `class` | `string` | no | `error-message` | CSS `class` to set on the wrapper element. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

