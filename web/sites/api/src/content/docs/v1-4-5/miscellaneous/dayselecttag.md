---
title: daySelectTag()
description: "Builds and returns a string containing a select form control for the days of the week based on the supplied name."
sidebar:
  label: daySelectTag()
  order: 0
---

## Signature

`daySelectTag()` — returns `any`




## Description

Builds and returns a string containing a select form control for the days of the week based on the supplied name.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | The day that should be selected initially. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- This &quot;Tag&quot; version of the function accepts a `name` and `selected` instead of binding to a model object ---&gt;
&lt;cfoutput&gt;
    #daySelectTag(name=&quot;dayOfWeek&quot;, selected=params.dayOfWeek)#
&lt;/cfoutput&gt;</pre>
