---
title: textFieldTag()
description: "Builds and returns a string containing a text field form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and th"
sidebar:
  label: textFieldTag()
  order: 0
---

## Signature

`textFieldTag()` — returns `any`




## Description

Builds and returns a string containing a text field form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | yes | — | Value to populate in tag's value attribute. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `type` | `string` | yes | `text` | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- Basic usage usually involves a `label`, `name`, and `value` ---&gt;
&lt;cfoutput&gt;
    #textFieldTag(label=&quot;Search&quot;, name=&quot;q&quot;, value=params.q)#
&lt;/cfoutput&gt;</pre>
