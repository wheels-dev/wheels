---
title: textAreaTag()
description: "Builds and returns a string containing a text area form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the"
sidebar:
  label: textAreaTag()
  order: 0
---

## Signature

`textAreaTag()` — returns `any`




## Description

Builds and returns a string containing a text area form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `content` | `string` | yes | — | Content to display in textarea on page load. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- Basic usage usually involves a `label`, `name`, and `password` ---&gt;
&lt;cfoutput&gt;
    #textAreaTag(label=&quot;Description&quot;, name=&quot;description&quot;, content=params.description)#
&lt;/cfoutput&gt;</pre>
