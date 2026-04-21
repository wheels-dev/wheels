---
title: selectTag()
description: "Builds and returns a string containing a select form control based on the supplied name and options. Note: Pass any additional arguments like class, rel, and id"
sidebar:
  label: selectTag()
  order: 0
---

## Signature

`selectTag()` — returns `any`




## Description

Builds and returns a string containing a select form control based on the supplied name and options. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `options` | `any` | yes | — | See documentation for select. |
| `selected` | `string` | yes | — | Value of option that should be selected by default. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `multiple` | `boolean` | yes | `false` | Whether to allow multiple selection of options in the select form control. |
| `valueField` | `string` | yes | — | See documentation for select. |
| `textField` | `string` | yes | — | See documentation for select. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- Controller code ---&gt;
&lt;cfset cities = model(&quot;city&quot;).findAll()&gt;

&lt;!--- View code ---&gt;
&lt;cfoutput&gt;
    #selectTag(name=&quot;cityId&quot;, options=cities)#
&lt;/cfoutput&gt;

&lt;!--- Do this when CFWheels isn''t grabbing the correct values for the `option`s'' values and display texts ---&gt;
&lt;cfoutput&gt;
	#selectTag(name=&quot;cityId&quot;, options=cities, valueField=&quot;id&quot;, textField=&quot;name&quot;)#
&lt;/cfoutput&gt;</pre>
