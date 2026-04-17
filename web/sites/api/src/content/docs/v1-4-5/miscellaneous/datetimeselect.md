---
title: dateTimeSelect()
description: "Builds and returns a string containing six select form controls (three for date selection and the remaining three for time selection) based on the supplied obje"
sidebar:
  label: dateTimeSelect()
  order: 0
---

## Signature

`dateTimeSelect()` — returns `any`




## Description

Builds and returns a string containing six select form controls (three for date selection and the remaining three for time selection) based on the supplied objectName and property.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | yes | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out. |
| `position` | `string` | yes | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out. |
| `dateOrder` | `string` | yes | `month,day,year` | Use to change the order of or exclude date select tags. |
| `dateSeperator` | `string` | yes | — | Use to change the character that is displayed between the date select tags. |
| `startYear` | `numeric` | yes | `2009` | First year in select list. |
| `startYear` | `numeric` | yes | `2019` | Last year in select list. |
| `monthDisplay` | `string` | yes | `names` | Pass in names, numbers, or abbreviations to control display. |
| `timeOrder` | `string` | yes | `hour,minute,second` | Use to change the order of or exclude time select tags. |
| `timeSeparator` | `string` | yes | `:` | Use to change the character that is displayed between the time select tags. |
| `minuteStep` | `numeric` | yes | `1` | Pass in 10 to only show minute 10, 20, 30, etc. |
| `secondStep` | `numeric` | yes | `1` | Pass in 10 to only show seconds 10, 20, 30, etc |
| `separator` | `string` | yes | `-` | Use to change the character that is displayed between the first and second set of select tags. |
| `includeBlank` | `any` | yes | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | yes | `false` | The label text to use in the form control. |
| `labelPlacement` | `string` | yes | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | yes | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | yes | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | yes | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | yes | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | yes | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | yes | `fieldWithErrors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `combine` | `boolean` | yes | — | Set to false to not combine the select parts into a single DateTime object. |
| `twelveHour` | `boolean` | yes | `false` | whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs |

## Examples

<pre>dateTimeSelect(objectName, property [, association, position, dateOrder, dateSeparator, startYear, endYear, monthDisplay, timeOrder, timeSeparator, minuteStep, secondStep, separator, includeBlank, label, labelPlacement, prepend, append, prependToLabel, appendToLabel, errorElement, errorClass, combine, twelveHour ]) &lt;!--- View code ---&gt;
&lt;cfoutput&gt;
    #dateTimeSelect(objectName=&quot;article&quot;, property=&quot;publishedAt&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Show fields for month, day, hour, and minute ---&gt;
&lt;cfoutput&gt;
    #dateTimeSelect(objectName=&quot;appointment&quot;, property=&quot;dateTimeStart&quot;, dateOrder=&quot;month,day&quot;, timeOrder=&quot;hour,minute&quot;)#
&lt;/cfoutput&gt;</pre>
