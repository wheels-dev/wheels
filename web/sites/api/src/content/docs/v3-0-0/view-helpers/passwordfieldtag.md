---
title: passwordFieldTag()
description: "Builds and returns a string containing a password field form control based on the supplied name."
sidebar:
  label: passwordFieldTag()
  order: 0
---

## Signature

`passwordFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a password field form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | no | — | Value to populate in tag's value attribute. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic Password Field
&lt;cfoutput&gt;
    #passwordFieldTag(label=&quot;Password&quot;, name=&quot;password&quot;, value=&quot;&quot;)#
&lt;/cfoutput&gt;

2. Label Placement Before Input
&lt;cfoutput&gt;
    #passwordFieldTag(label=&quot;Password&quot;, name=&quot;password&quot;, labelPlacement=&quot;before&quot;)#
&lt;/cfoutput&gt;

3. Wrapping Input with Custom HTML
&lt;cfoutput&gt;
    #passwordFieldTag(
        label=&quot;Enter Password&quot;,
        name=&quot;password&quot;,
        prepend=&quot;&lt;div class='input-group'&gt;&quot;,
        append=&quot;&lt;/div&gt;&quot;
    )#
&lt;/cfoutput&gt;

4. Custom Label Decoration
&lt;cfoutput&gt;
    #passwordFieldTag(
        label=&quot;Password&quot;,
        name=&quot;password&quot;,
        prependToLabel=&quot;&lt;strong&gt;&quot;,
        appendToLabel=&quot;&lt;/strong&gt;&quot;
    )#
&lt;/cfoutput&gt;
</code></pre>
