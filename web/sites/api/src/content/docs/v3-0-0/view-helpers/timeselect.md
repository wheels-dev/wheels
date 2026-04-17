---
title: timeSelect()
description: "Builds and returns three select form controls for hours, minutes, and seconds, based on the supplied object name and property. It is useful when you want users"
sidebar:
  label: timeSelect()
  order: 0
---

## Signature

`timeSelect()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns three select form controls for hours, minutes, and seconds, based on the supplied object name and property. It is useful when you want users to input a time in a structured way without manually typing values. You can configure it to display only specific units (such as hours and minutes), control step intervals for minutes or seconds, display in 12-hour format with AM/PM, and customize labels, error handling, and additional HTML wrapping. By default, the three selects are ordered as hour, minute, and second, but you can change this order or exclude parts completely.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | no | — | The variable name of the object to build the form control for. |
| `property` | `string` | no | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out. |
| `order` | `string` | no | `hour,minute,second` | Use to change the order of or exclude time select tags. |
| `separator` | `string` | no | `:` | Use to change the character that is displayed between the time select tags. |
| `minuteStep` | `numeric` | no | `1` | Pass in 10 to only show minute 10, 20, 30, etc. |
| `secondStep` | `numeric` | no | `1` | Pass in 10 to only show seconds 10, 20, 30, etc. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | no | `false` | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | `field-with-errors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `combine` | `boolean` | no | — | Set to false to not combine the select parts into a single DateTime object. |
| `twelveHour` | `boolean` | no | `false` | whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>1. Basic usage: create hour, minute, and second selects for a property
timeSelect(objectName=&quot;business&quot;, property=&quot;openUntil&quot;)

2. Only display hour and minute selectors
timeSelect(objectName=&quot;business&quot;, property=&quot;openUntil&quot;, order=&quot;hour,minute&quot;)

3. Limit minutes to 15-minute intervals (00, 15, 30, 45)
timeSelect(objectName=&quot;appointment&quot;, property=&quot;dateTimeStart&quot;, minuteStep=15)

4. Use 12-hour format with AM/PM
timeSelect(objectName=&quot;event&quot;, property=&quot;startTime&quot;, twelveHour=true)

5. Add a blank option at the top
timeSelect(objectName=&quot;schedule&quot;, property=&quot;startTime&quot;, includeBlank=&quot;- Select Time -&quot;)

6. Customize the label and append helper text
timeSelect(objectName=&quot;meeting&quot;, property=&quot;endTime&quot;, label=&quot;End Time&quot;, append=&quot;(select carefully)&quot;)
</code></pre>
