---
title: monthSelectTag()
description: "Builds and returns a string containing a select form control for the months of the year based on the supplied name."
sidebar:
  label: monthSelectTag()
  order: 0
---

## Signature

`monthSelectTag()` — returns `any`




## Description

Builds and returns a string containing a select form control for the months of the year based on the supplied name.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | The month that should be selected initially. |
| `monthDisplay` | `string` | yes | `names` | See documentation for dateSelect. |
| `monthNames` | `string` | yes | `January,February,March,April,May,June,July,August,September,October,November,December` | See documentation for dateSelect. |
| `monthAbbreviations` | `string` | yes | `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec` | See documentation for dateSelect. |
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
    #monthSelectTag(name=&quot;monthOfBirthday&quot;, selected=params.monthOfBirthday)#
&lt;/cfoutput&gt;</pre>
