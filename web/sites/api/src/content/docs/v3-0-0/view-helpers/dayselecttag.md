---
title: daySelectTag()
description: "Builds and returns a string containing a <code>select</code> form control for the days of the week based on the supplied name. This version works without bindin"
sidebar:
  label: daySelectTag()
  order: 0
---

## Signature

`daySelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a <code>select</code> form control for the days of the week based on the supplied name. This version works without binding to a model object.



## Parameters

<div class="wd-params-table">

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
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |
| `$now` | `date` | no | `[runtime expression]` |  |

</div>

## Examples

<pre><code class='javascript'>Example 1: Basic usage
#daySelectTag(name="dayOfWeek", selected=params.dayOfWeek)#

Generates a standard select dropdown for all days of the week.

Pre-selects the value from params.dayOfWeek if available.

---

Example 2: Include a blank option
#daySelectTag(name="meetingDay", selected=params.meetingDay, includeBlank=true)#

Adds a blank option at the top so users can select nothing.

---

Example 3: Custom label before the field
#daySelectTag(
    name="deliveryDay",
    selected=params.deliveryDay,
    label="Choose delivery day:",
    labelPlacement="before"
)#

Adds a label that appears before the dropdown.

---

Example 4: Prepend and append HTML
#daySelectTag(
    name="eventDay",
    prepend="&lt;div class='select-wrapper'&gt;",
    append="&lt;/div&gt;"
)#

Wraps the dropdown inside a &lt;div&gt; for styling purposes.</code></pre>
