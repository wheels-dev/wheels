---
title: minuteSelectTag()
description: "Builds and returns a string containing one <code>select</code> form control for the minutes of an hour based on the supplied name."
sidebar:
  label: minuteSelectTag()
  order: 0
---

## Signature

`minuteSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing one <code>select</code> form control for the minutes of an hour based on the supplied name.



## Parameters

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
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |
| `$now` | `date` | no | `[runtime expression]` |  |

## Examples

<pre>// This &quot;Tag&quot; version of the function accepts a `name` and `selected` instead of binding to a model object 
&lt;cfoutput&gt;
    #minuteSelectTag(name=&quot;minuteOfMeeting&quot;, value=params.minuteOfMeeting)#
&lt;/cfoutput&gt;

// Only show 15-minute intervals 
&lt;cfoutput&gt;
	#minuteSelectTag(name=&quot;minuteOfMeeting&quot;, value=params.minuteOfMeeting, minuteStep=15)#
&lt;/cfoutput&gt;</pre>
