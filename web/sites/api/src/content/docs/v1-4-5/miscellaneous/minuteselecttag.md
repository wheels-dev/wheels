---
title: minuteSelectTag()
description: "Builds and returns a string containing one select form control for the minutes of an hour based on the supplied name."
sidebar:
  label: minuteSelectTag()
  order: 0
---

## Signature

`minuteSelectTag()` — returns `any`




## Description

Builds and returns a string containing one select form control for the minutes of an hour based on the supplied name.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | The minute that should be selected initially. |
| `minuteStep` | `numeric` | yes | `1` | See documentation for timeSelect. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

## Examples

<pre>&lt;!--- This &quot;Tag&quot; version of the function accepts a `name` and `selected` instead of binding to a model object ---&gt;
&lt;cfoutput&gt;
    #minuteSelectTag(name=&quot;minuteOfMeeting&quot;, value=params.minuteOfMeeting)#
&lt;/cfoutput&gt;

&lt;!--- Only show 15-minute intervals ---&gt;
&lt;cfoutput&gt;
	#minuteSelectTag(name=&quot;minuteOfMeeting&quot;, value=params.minuteOfMeeting, minuteStep=15)#
&lt;/cfoutput&gt;</pre>
