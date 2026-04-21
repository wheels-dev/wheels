---
title: secondSelectTag()
description: "Generates an HTML &lt;select&gt; form control populated with seconds (0–59) for a minute. You can bind it to a form parameter or manually set a selected value,"
sidebar:
  label: secondSelectTag()
  order: 0
---

## Signature

`secondSelectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Generates an HTML &lt;select&gt; form control populated with seconds (0–59) for a minute. You can bind it to a form parameter or manually set a selected value, control the step interval, include a blank option, and customize labels and HTML attributes. This is especially useful for time selection forms, like setting the seconds for a scheduled task or timestamp input.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `selected` | `string` | no | — | The day that should be selected initially. |
| `secondStep` | `numeric` | no | `1` | Pass in 10 to only show seconds 10, 20, 30, etc. |
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

<pre><code class='javascript'>1. Basic select for seconds (0–59)
secondSelectTag(name=&quot;secondsToLaunch&quot;)

2. Pre-select a second based on a parameter
secondSelectTag(name=&quot;secondsToLaunch&quot;, selected=params.secondsToLaunch)

3. Only show 15-second intervals
secondSelectTag(name=&quot;secondsToLaunch&quot;, selected=params.secondsToLaunch, secondStep=15)

4. Include a blank option with custom text
secondSelectTag(name=&quot;secondsToLaunch&quot;, includeBlank=&quot;- Select Seconds -&quot;)

5. Add a label around the select control
secondSelectTag(name=&quot;secondsToLaunch&quot;, label=&quot;Launch Second&quot;, labelPlacement=&quot;around&quot;)</code></pre>
