---
title: dateTimeSelectTags()
description: "Builds and returns a string containing six select form controls (three for date selection and the remaining three for time selection) based on a name."
sidebar:
  label: dateTimeSelectTags()
  order: 0
---

## Signature

`dateTimeSelectTags()` — returns `any`




## Description

Builds and returns a string containing six select form controls (three for date selection and the remaining three for time selection) based on a name.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | See documentation for selectTag. |
| `dateOrder` | `string` | yes | `month,day,year` | See documentation for dateTimeSelect. |
| `dateSeparator` | `string` | yes | — | See documentation for dateTimeSelect. |
| `startYear` | `numeric` | yes | `2010` | See documentation for dateSelect. |
| `endYear` | `numeric` | yes | `2020` | See documentation for dateSelect. |
| `monthDisplay` | `string` | yes | `names` | See documentation for dateSelect. |
| `monthNames` | `string` | yes | `January,February,March,April,May,June,July,August,September,October,November,December` | See documentation for dateSelect. |
| `monthAbbreviations` | `string` | yes | `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec` | See documentation for dateSelect. |
| `timeOrder` | `string` | yes | `hour,minute,second` | See documentation for dateTimeSelect. |
| `timeSeparator` | `string` | yes | `:` | See documentation for dateTimeSelect. |
| `minuteStep` | `numeric` | yes | `1` | See documentation for timeSelect. |
| `secondStep` | `numeric` | yes | `1` | See documentation for timeSelect. |
| `separator` | `string` | yes | `-` | See documentation for dateTimeSelect. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for dateSelect. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `combine` | `boolean` | yes | — | See documentation for dateSelect. |
| `twelveHour` | `boolean` | yes | `false` | See documentation for timeSelect. |

## Examples

<pre>&lt;!--- This &quot;Tag&qquot; version of the function accepts a `name` and `selected` instead of binding to a model object ---&gt;
&lt;cfoutput&gt;
    #dateTimeSelectTags(name=&quot;dateTimeStart&quot;, selected=params.dateTimeStart)#
&lt;/cfoutput&gt;

&lt;!--- Show fields for month, day, hour, and minute ---&gt;
&lt;cfoutput&gt;
	#dateTimeSelectTags(name=&quot;dateTimeStart&quot;, selected=params.dateTimeStart, dateOrder=&quot;month,day&quot;, timeOrder=&quot;hour,minute&quot;)#
&lt;/cfoutput&gt;</pre>
