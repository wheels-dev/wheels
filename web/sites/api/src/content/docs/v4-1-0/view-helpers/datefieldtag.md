---
title: dateFieldTag()
description: "Builds and returns a string containing a date field form control based on the supplied name."
sidebar:
  label: dateFieldTag()
  order: 0
---

## Signature

`dateFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a date field form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | no | — | Value to populate in tag's value attribute. |
| `min` | `string` | no | — | Minimum allowed date (YYYY-MM-DD format). |
| `max` | `string` | no | — | Maximum allowed date (YYYY-MM-DD format). |
| `step` | `string` | no | — |  |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic date field with a name and label
#dateFieldTag(name=&quot;startDate&quot;, label=&quot;Start Date&quot;)#

// 2. Pre-filled date value with min/max constraints
#dateFieldTag(name=&quot;eventDate&quot;, value=&quot;2024-06-15&quot;, min=&quot;2024-01-01&quot;, max=&quot;2024-12-31&quot;, label=&quot;Event Date&quot;)#

// 3. Date field with extra HTML attributes passed through
#dateFieldTag(name=&quot;dueDate&quot;, label=&quot;Due Date&quot;, class=&quot;form-control&quot;, id=&quot;due-date-input&quot;)#
</code></pre>
