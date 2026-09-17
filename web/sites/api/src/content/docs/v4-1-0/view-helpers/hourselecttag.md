---
title: hourSelectTag()
description: "Builds and returns a string containing one <code>select</code> form control for the hours of the day based on the supplied name."
sidebar:
  label: hourSelectTag()
  order: 0
---

## Signature

`hourSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing one <code>select</code> form control for the hours of the day based on the supplied name.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | The hour that should be selected initially. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `twelveHour` | `boolean` | no | `false` | whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |
| `$now` | `date` | no | `[runtime expression]` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic usage — render a select control for hours of the day
#hourSelectTag(name=&quot;hourOfMeeting&quot;, selected=params.hourOfMeeting)#

// 2. Show hours in 12-hour (AM/PM) format instead of 24-hour format
#hourSelectTag(name=&quot;hourOfMeeting&quot;, selected=params.hourOfMeeting, twelveHour=true)#

// 3. Include a blank option as a placeholder prompt and add a label
#hourSelectTag(name=&quot;startHour&quot;, selected=params.startHour, includeBlank=&quot;-- Select Hour --&quot;, label=&quot;Start Hour&quot;)#
</code></pre>
