---
title: timeSelect()
description: "Builds and returns a string containing three select form controls for hour, minute, and second based on the supplied objectName and property."
sidebar:
  label: timeSelect()
  order: 0
---

## Signature

`timeSelect()` — returns `any`




## Description

Builds and returns a string containing three select form controls for hour, minute, and second based on the supplied objectName and property.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | See documentation for textField. |
| `property` | `string` | yes | — | See documentation for textField. |
| `association` | `string` | yes | — | See documentation for textfield. |
| `position` | `string` | yes | — | See documentation for textfield. |
| `order` | `string` | yes | `hour,minute,second` | Use to change the order of or exclude time select tags. |
| `separator` | `string` | yes | `:` | Use to change the character that is displayed between the time select tags. |
| `minuteStep` | `numeric` | yes | `1` | Pass in 10 to only show minute 10, 20, 30, etc. |
| `secondStep` | `numeric` | yes | `1` | Pass in 10 to only show seconds 10, 20, 30, etc. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | `false` | See documentation for dateSelect. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `errorElement` | `string` | yes | `span` | See documentation for textField. |
| `errorClass` | `string` | yes | `fieldWithErrors` | See documentation for textField. |
| `combine` | `boolean` | yes | — | See documentation for dateSelect. |
| `twelveHour` | `boolean` | yes | `false` | whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs |

</div>

## Examples

<pre>&lt;!--- View code ---&gt;
&lt;cfoutput&gt;
    #timeSelect(objectName=&quot;business&quot;, property=&quot;openUntil&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Show fields for hour and minute ---&gt;
&lt;cfoutput&gt;
	#timeSelect(objectName=&quot;business&quot;, property=&quot;openUntil&quot;, order=&quot;hour,minute&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Only show 15-minute intervals ---&gt;
&lt;cfoutput&gt;
	#timeSelect(objectName=&quot;appointment&quot;, property=&quot;dateTimeStart&quot;, minuteStep=15)#
&lt;/cfoutput&gt;</pre>
