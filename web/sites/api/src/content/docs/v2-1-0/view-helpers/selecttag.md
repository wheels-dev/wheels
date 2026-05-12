---
title: selectTag()
description: "Builds and returns a string containing a select form control based on the supplied name and options."
sidebar:
  label: selectTag()
  order: 0
---

## Signature

`selectTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a select form control based on the supplied name and options.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `options` | `any` | yes | — | A collection to populate the select form control with. Can be a query recordset or an array of objects. |
| `selected` | `string` | no | — | Value of option that should be selected by default. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `multiple` | `boolean` | no | `false` | Whether to allow multiple selection of options in the select form control. |
| `valueField` | `string` | no | — | The column or property to use for the value of each list element. Used only when a query or array of objects has been supplied in the options argument.  Required when specifying `textField` |
| `textField` | `string` | no | — | The column or property to use for the value of each list element that the end user will see. Used only when a query or array of objects has been supplied in the options argument. Required when specifying `valueField` |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// Controller code
cities = model(&quot;city&quot;).findAll()&gt;

&lt;!--- View code---&gt;
#selectTag(name=&quot;cityId&quot;, options=cities)#

&lt;!---
	Do this when CFWheels isn't grabbing the correct values for the `option`s' values and display texts
	Note that `valueField` and `textField` are both required when using this option
---&gt;
#selectTag(name=&quot;cityId&quot;, options=cities, valueField=&quot;id&quot;, textField=&quot;name&quot;)#
</code></pre>
