---
title: timeSelectTags()
description: "Builds and returns three <code>&lt;select&gt;</code> form controls for hours, minutes, and seconds based on the supplied name. This is the tag-based version of"
sidebar:
  label: timeSelectTags()
  order: 0
---

## Signature

`timeSelectTags()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns three <code>&lt;select&gt;</code> form controls for hours, minutes, and seconds based on the supplied name. This is the tag-based version of <code>timeSelect()</code>, meaning it does not bind to a model object but instead works with raw form field names. You can control the order of the selects, limit minute and second intervals, display in 12-hour format with AM/PM, and include custom labels, error handling, and HTML wrappers.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | Value of option that should be selected by default. |
| `order` | `string` | no | `hour,minute,second` | Use to change the order of or exclude time select tags. |
| `separator` | `string` | no | `:` | Use to change the character that is displayed between the time select tags. |
| `minuteStep` | `numeric` | no | `1` | Pass in 10 to only show minute 10, 20, 30, etc. |
| `secondStep` | `numeric` | no | `1` | Pass in 10 to only show seconds 10, 20, 30, etc. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `combine` | `boolean` | no | — | Set to false to not combine the select parts into a single DateTime object. |
| `twelveHour` | `boolean` | no | `false` | whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>1. Basic usage: creates hour, minute, and second selects
timeSelectTags(name=&quot;timeOfMeeting&quot;, selected=params.timeOfMeeting)

2. Only show hour and minute selects
timeSelectTags(name=&quot;timeOfMeeting&quot;, selected=params.timeOfMeeting, order=&quot;hour,minute&quot;)

3. Show 15-minute intervals
timeSelectTags(name=&quot;reminderTime&quot;, minuteStep=15)

4. Display in 12-hour format with AM/PM
timeSelectTags(name=&quot;eventStart&quot;, twelveHour=true)

5. Include a blank option
timeSelectTags(name=&quot;timeSlot&quot;, includeBlank=&quot;- Select Time -&quot;)

6. Add a label and append helper text
timeSelectTags(name=&quot;appointmentEnd&quot;, label=&quot;End Time&quot;, append=&quot;(HH:MM:SS)&quot;)
</code></pre>
