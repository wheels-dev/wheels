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
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

