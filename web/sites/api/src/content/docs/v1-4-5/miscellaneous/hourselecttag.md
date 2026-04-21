---
title: hourSelectTag()
description: "Builds and returns a string containing one select form control for the hours of the day based on the supplied name."
sidebar:
  label: hourSelectTag()
  order: 0
---

## Signature

`hourSelectTag()` — returns `any`




## Description

Builds and returns a string containing one select form control for the hours of the day based on the supplied name.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | The hour that should be selected initially. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `twelveHour` | `boolean` | yes | `false` | See documentation for timeSelect. |

</div>

## Examples

<pre>&lt;!--- This &quot;Tag&quot; version of the function accepts a `name` and `selected` instead of binding to a model object ---&gt;
&lt;cfoutput&gt;
    #hourSelectTag(name=&quot;hourOfMeeting&quot;, selected=params.hourOfMeeting)#
&lt;/cfoutput&gt;

&lt;!--- Show 12 hours instead of 24 ---&gt;
&lt;cfoutput&gt;
	#hourSelectTag(name=&quot;hourOfMeeting&quot;, selected=params.hourOfMeeting, twelveHour=true)#
&lt;/cfoutput&gt;</pre>
