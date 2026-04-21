---
title: dateTimeSelectTags()
description: "Builds and returns a string containing six <code>select</code> form controls (three for date selection and the remaining three for time selection) based on a na"
sidebar:
  label: dateTimeSelectTags()
  order: 0
---

## Signature

`dateTimeSelectTags()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing six <code>select</code> form controls (three for date selection and the remaining three for time selection) based on a name.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | Value of option that should be selected by default. |
| `dateOrder` | `string` | no | `month,day,year` | Use to change the order of or exclude date select tags. |
| `dateSeparator` | `string` | no | ` ` | [see:dateTimeSelect]. |
| `startYear` | `numeric` | no | `2012` | First year in `select` list. |
| `endYear` | `numeric` | no | `2022` | Last year in `select` list. |
| `monthDisplay` | `string` | no | `names` | Pass in names, numbers, or abbreviations to control display. |
| `monthNames` | `string` | no | `January,February,March,April,May,June,July,August,September,October,November,December` | [see:dateSelect]. |
| `monthAbbreviations` | `string` | no | `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec` | [see:dateSelect]. |
| `timeOrder` | `string` | no | `hour,minute,second` | Use to change the order of or exclude time select tags. |
| `timeSeparator` | `string` | no | `:` | Use to change the character that is displayed between the time select tags. |
| `minuteStep` | `numeric` | no | `1` | Pass in 10 to only show minute 10, 20, 30, etc. |
| `secondStep` | `numeric` | no | `1` | Pass in 10 to only show seconds 10, 20, 30, etc. |
| `separator` | `string` | no | ` - ` | Use to change the character that is displayed between the first and second set of select tags. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `combine` | `boolean` | no | — | Set to false to not combine the select parts into a single DateTime object. |
| `twelveHour` | `boolean` | no | `false` | whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- This &quot;Tag&quot; version of the function accepts a `name` and `selected` instead of binding to a model object---&gt;
#dateTimeSelectTags(name=&quot;dateTimeStart&quot;, selected=params.dateTimeStart)#

&lt;!--- Show fields for month, day, hour, and minute---&gt;
#dateTimeSelectTags(name=&quot;dateTimeStart&quot;, selected=params.dateTimeStart, dateOrder=&quot;month,day&quot;, timeOrder=&quot;hour,minute&quot;)#</pre>
