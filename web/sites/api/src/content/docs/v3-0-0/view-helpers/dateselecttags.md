---
title: dateSelectTags()
description: "dateSelectTags() is similar to dateSelect(), but instead of binding to a model object, it works directly with a name and selected value. It generates three sele"
sidebar:
  label: dateSelectTags()
  order: 0
---

## Signature

`dateSelectTags()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

dateSelectTags() is similar to dateSelect(), but instead of binding to a model object, it works directly with a name and selected value. It generates three select dropdowns (month, day, year) for form tags.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | Value of option that should be selected by default. |
| `order` | `string` | no | `month,day,year` | Use to change the order of or exclude date `select` tags. |
| `separator` | `string` | no | ` ` | [see:dateSelect]. |
| `startYear` | `numeric` | no | `2018` | First year in `select` list. |
| `endYear` | `numeric` | no | `2028` | Last year in `select` list. |
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
| `combine` | `boolean` | no | — | Set to false to not combine the select parts into a single DateTime object. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |
| `$now` | `date` | no | `[runtime expression]` |  |

## Examples

<pre><code class='javascript'>Example 1: Basic usage
#dateSelectTags(name="dateStart", selected=params.dateStart)#

Outputs month/day/year selects with the value pre-selected from params.dateStart.

---

Example 2: Month and year only
#dateSelectTags(name="expiration", selected=params.expiration, order="month,year")#

Useful for credit card expiration date inputs.

Only month and year dropdowns appear.

---

Example 3: Custom year range
#dateSelectTags(name="eventDate", startYear=2000, endYear=2030)#

Dropdown shows years 2000–2030.

---

Example 4: Custom month display
#dateSelectTags(name="anniversary", monthDisplay="abbreviations")#

Months display as Jan, Feb, Mar… instead of full names.

---

Example 5: Include blank options
#dateSelectTags(name="graduationDate", includeBlank="- Select Date -")#

Adds a blank option at the top of each dropdown with - Select Date -.

---

Example 6: Using labels and custom HTML
#dateSelectTags(name="hireDate", label="Hire Date", labelPlacement="before", prepend="&lt;div class='date-wrapper'&gt;", append="&lt;/div>")#

Adds a label and wraps selects inside a &lt;div&gt; for styling.</code></pre>
