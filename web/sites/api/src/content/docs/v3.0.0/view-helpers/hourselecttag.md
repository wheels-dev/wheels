---
title: hourSelectTag()
description: "Builds and returns a &lt;select&gt; form control for choosing an hour of the day. By default, hours are shown in 24-hour format (00–23), but you can switch to 1"
sidebar:
  label: hourSelectTag()
  order: 0
---

## Signature

`hourSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a &lt;select&gt; form control for choosing an hour of the day. By default, hours are shown in 24-hour format (00–23), but you can switch to 12-hour format with an accompanying AM/PM dropdown.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | The day that should be selected initially. |
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

## Examples

<pre><code class='javascript'>1. Basic 24-hour select
#hourSelectTag(name=&quot;meetingHour&quot;)#

// Output (simplified):
// &lt;select name=&quot;meetingHour&quot;&gt;
//   &lt;option value=&quot;00&quot;&gt;00&lt;/option&gt;
//   &lt;option value=&quot;01&quot;&gt;01&lt;/option&gt;
//   ...
//   &lt;option value=&quot;23&quot;&gt;23&lt;/option&gt;
// &lt;/select&gt;

2. Pre-select an hour
#hourSelectTag(name=&quot;meetingHour&quot;, selected=&quot;14&quot;)#

// Output (simplified):
// &lt;option value=&quot;14&quot; selected=&quot;selected&quot;&gt;14&lt;/option&gt;

3. Include a blank option
#hourSelectTag(name=&quot;meetingHour&quot;, includeBlank=&quot;- Select Hour -&quot;)#

// Output (simplified):
// &lt;option value=&quot;&quot;&gt;- Select Hour -&lt;/option&gt;
// &lt;option value=&quot;00&quot;&gt;00&lt;/option&gt;
// ...

4. Use 12-hour format with AM/PM
#hourSelectTag(name=&quot;meetingHour&quot;, twelveHour=true, selected=&quot;3&quot;)#

// Output (simplified):
// &lt;select name=&quot;meetingHour&quot;&gt;
//   &lt;option value=&quot;01&quot;&gt;01&lt;/option&gt;
//   &lt;option value=&quot;02&quot;&gt;02&lt;/option&gt;
//   &lt;option value=&quot;03&quot; selected=&quot;selected&quot;&gt;03&lt;/option&gt;
//   ...
//   &lt;option value=&quot;12&quot;&gt;12&lt;/option&gt;
// &lt;/select&gt;

// &lt;select name=&quot;meetingHourMeridian&quot;&gt;
//   &lt;option value=&quot;AM&quot;&gt;AM&lt;/option&gt;
//   &lt;option value=&quot;PM&quot;&gt;PM&lt;/option&gt;
// &lt;/select&gt;
</code></pre>
