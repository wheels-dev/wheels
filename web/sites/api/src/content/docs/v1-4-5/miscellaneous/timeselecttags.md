---
title: timeSelectTags()
description: "Builds and returns a string containing three select form controls for hour, minute, and second based on name."
sidebar:
  label: timeSelectTags()
  order: 0
---

## Signature

`timeSelectTags()` — returns `any`




## Description

Builds and returns a string containing three select form controls for hour, minute, and second based on name.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | See documentation for selectTag. |
| `order` | `string` | yes | `hour,minute,second` | See documentation for timeSelect. |
| `separator` | `string` | yes | `:` | See documentation for timeSelect. |
| `minuteStep` | `numeric` | yes | `1` | See documentation for timeSelect. |
| `secondStep` | `numeric` | yes | `1` | See documentation for timeSelect. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for dateSelect. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `combine` | `boolean` | yes | — | See documentation for dateSelect. |
| `twelveHour` | `boolean` | yes | `false` | See documentation for timeSelect. |

</div>

## Examples

<pre>&lt;!--- This &quot;Tag&quot; version of function accepts `name` and `selected` instead of binding to a model object ---&gt;
&lt;cfoutput&gt;
    ##timeSelectTags(name=&quot;timeOfMeeting&quot; selected=params.timeOfMeeting)##
&lt;/cfoutput&gt;

&lt;!--- Show fields for `hour` and `minute` only ---&gt;
&lt;cfoutput&gt;
	##timeSelectTags(name=&quot;timeOfMeeting&quot;, selected=params.timeOfMeeting, order=&quot;hour,minute&quot;)##
&lt;/cfoutput&gt;</pre>
