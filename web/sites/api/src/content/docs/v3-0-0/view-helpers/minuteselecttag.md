---
title: minuteSelectTag()
description: "Builds and returns a &lt;select&gt; dropdown for the minutes of an hour (0–59). You can customize the selected value, increment steps (e.g., 5, 10, 15 minutes),"
sidebar:
  label: minuteSelectTag()
  order: 0
---

## Signature

`minuteSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a &lt;select&gt; dropdown for the minutes of an hour (0–59). You can customize the selected value, increment steps (e.g., 5, 10, 15 minutes), label placement, and include a blank option. Useful for forms where users pick a time.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | The day that should be selected initially. |
| `minuteStep` | `numeric` | no | `1` | Pass in 10 to only show minute 10, 20, 30, etc. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |
| `$now` | `date` | no | `[runtime expression]` |  |

</div>

## Examples

<pre><code class='javascript'>1. Basic Minute Select
minuteSelectTag(name=&quot;minuteOfMeeting&quot;, selected=params.minuteOfMeeting)

2. 15-Minute Intervals
minuteSelectTag(name=&quot;minuteOfMeeting&quot;, selected=params.minuteOfMeeting, minuteStep=15)

3. Include Blank Option
minuteSelectTag(name=&quot;minuteOfMeeting&quot;, includeBlank=&quot;- Select Minute -&quot;)

4. Using Label
minuteSelectTag(name=&quot;minuteOfMeeting&quot;, label=&quot;Select Minute&quot;)

5. Custom Label Placement
minuteSelectTag(name=&quot;minuteOfMeeting&quot;, label=&quot;Minute&quot;, labelPlacement=&quot;after&quot;)

</code></pre>
