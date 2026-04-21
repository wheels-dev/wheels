---
title: monthSelectTag()
description: "Generates a &lt;select&gt; dropdown for selecting a month. You can customize its options, labels, and display format. Unlike dateSelect, this function focuses o"
sidebar:
  label: monthSelectTag()
  order: 0
---

## Signature

`monthSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Generates a &lt;select&gt; dropdown for selecting a month. You can customize its options, labels, and display format. Unlike dateSelect, this function focuses only on the month portion.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | The month that should be selected initially. |
| `monthDisplay` | `string` | no | `names` | Pass in names, numbers, or abbreviations to control display. |
| `monthNames` | `string` | no | `January,February,March,April,May,June,July,August,September,October,November,December` | [see:dateSelect]. |
| `monthAbbreviations` | `string` | no | `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec` | [see:dateSelect]. |
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

<pre><code class='javascript'>1. Basic usage
monthSelectTag(name=&quot;monthOfBirthday&quot;, selected=params.monthOfBirthday)

2. Display months as numbers
monthSelectTag(name=&quot;monthOfHire&quot;, selected=3, monthDisplay=&quot;numbers&quot;)

3. Display months as abbreviations
monthSelectTag(name=&quot;monthOfEvent&quot;, selected=&quot;Jun&quot;, monthDisplay=&quot;abbreviations&quot;)

4. Include a blank option
monthSelectTag(name=&quot;monthOfAppointment&quot;, includeBlank=&quot;- Select Month -&quot;)

5. Custom label and wrapping
monthSelectTag(name=&quot;monthOfSubscription&quot;, label=&quot;Subscription Month:&quot;, labelPlacement=&quot;before&quot;)
</code></pre>
