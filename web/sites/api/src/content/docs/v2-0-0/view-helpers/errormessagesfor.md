---
title: errorMessagesFor()
description: "Builds and returns a list (<code>ul</code> tag with a default <code>class</code> of <code>error-messages</code>) containing all the error messages for all the p"
sidebar:
  label: errorMessagesFor()
  order: 0
---

## Signature

`errorMessagesFor()` — returns `string`

**Available in:** `controller`
**Category:** Error Functions

## Description

Builds and returns a list (<code>ul</code> tag with a default <code>class</code> of <code>error-messages</code>) containing all the error messages for all the properties of the object.
Returns an empty string if no errors exist.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | The variable name of the object to display error messages for. |
| `class` | `string` | no | `error-messages` | CSS `class` to set on the `ul` element. |
| `showDuplicates` | `boolean` | no | `true` | Whether or not to show duplicate error messages. |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

