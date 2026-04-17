---
title: passwordFieldTag()
description: "Builds and returns a string containing a password field form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, an"
sidebar:
  label: passwordFieldTag()
  order: 0
---

## Signature

`passwordFieldTag()` — returns `any`




## Description

Builds and returns a string containing a password field form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `value` | `string` | yes | — | See documentation for textFieldTag. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

## Examples

<pre>&lt;!--- Basic usage usually involves a `label`, `name`, and `value` ---&gt;
&lt;cfoutput&gt;
    #passwordFieldTag(label=&quot;Password&quot;, name=&quot;password&quot;, value=params.password)#
&lt;/cfoutput&gt;</pre>
