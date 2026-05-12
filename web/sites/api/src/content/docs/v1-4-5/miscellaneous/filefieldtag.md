---
title: fileFieldTag()
description: "Builds and returns a string containing a file form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the gene"
sidebar:
  label: fileFieldTag()
  order: 0
---

## Signature

`fileFieldTag()` — returns `any`




## Description

Builds and returns a string containing a file form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- Basic usage usually involves a `label`, `name`, and `value` ---&gt;
&lt;cfoutput&gt;
    #fileFieldTag(label=&quot;Photo&quot;, name=&quot;photo&quot;, value=params.photo)#
&lt;/cfoutput&gt;</pre>
