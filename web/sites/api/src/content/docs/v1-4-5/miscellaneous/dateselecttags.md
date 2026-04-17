---
title: dateSelectTags()
description: "Builds and returns a string containing three select form controls (month, day, and year) based on a name and value."
sidebar:
  label: dateSelectTags()
  order: 0
---

## Signature

`dateSelectTags()` — returns `any`




## Description

Builds and returns a string containing three select form controls (month, day, and year) based on a name and value.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | See documentation for selectTag. |
| `order` | `string` | yes | `month, day, year` | See documentation for dateSelect. |
| `separator` | `string` | yes | — | See documentation for dateSelect. |
| `startYear` | `numeric` | yes | `2010` | See documentation for dateSelect. |
| `endYear` | `numeric` | yes | `2020` | See documentation for dateSelect. |
| `monthDisplay` | `string` | yes | `names` | See documentation for dateSelect. |
| `monthNames` | `string` | yes | `January, February, March, April, May, June, July, August, September, October, November, December` | See documentation for dateSelect. |
| `monthAbbreviations` | `string` | yes | `Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec` | See documentation for dateSelect. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for dateSelect. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `combine` | `boolean` | yes | — | See documentation for dateSelect. |

## Examples

<pre>&lt;!--- This &quot;Tag&quot; version of function accepts `name` and `selected` instead of binding to a model object ---&gt;
&lt;cfoutput&gt;
	#dateSelectTags(name=&quot;dateStart&quot;, selected=params.dateStart)#
&lt;/cfoutput&gt;

&lt;!--- Show fields for month and year only ---&gt;
&lt;cfoutput&gt;
	#dateSelectTags(name=&quot;expiration&quot;, selected=params.expiration, order=&quot;month,year&quot;)#
&lt;/cfoutput&gt;</pre>
