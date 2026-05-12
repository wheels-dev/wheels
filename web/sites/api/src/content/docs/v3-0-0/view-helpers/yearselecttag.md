---
title: yearSelectTag()
description: "Builds and returns a string containing a <code>select</code> form control for a range of years based on the supplied name."
sidebar:
  label: yearSelectTag()
  order: 0
---

## Signature

`yearSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a <code>select</code> form control for a range of years based on the supplied name.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | The year that should be selected initially. |
| `startYear` | `numeric` | no | `2018` | First year in `select` list. |
| `endYear` | `numeric` | no | `2028` | Last year in `select` list. |
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

<pre><code class='javascript'>1. Basic year dropdown
yearSelectTag(name=&quot;yearOfBirthday&quot;, selected=params.yearOfBirthday)

2. Custom range (past 50 years, at least 18 years ago)
fiftyYearsAgo = Year(Now()) - 50;
eighteenYearsAgo = Year(Now()) - 18;

yearSelectTag(
    name=&quot;yearOfBirthday&quot;,
    selected=params.yearOfBirthday,
    startYear=fiftyYearsAgo,
    endYear=eighteenYearsAgo
)

3. Include a blank option
yearSelectTag(name=&quot;graduationYear&quot;, includeBlank=&quot;- Select Year -&quot;)

4. Add label with custom placement
yearSelectTag(
    name=&quot;yearOfHiring&quot;,
    label=&quot;Hiring Year&quot;,
    labelPlacement=&quot;aroundRight&quot;
)
</code></pre>
