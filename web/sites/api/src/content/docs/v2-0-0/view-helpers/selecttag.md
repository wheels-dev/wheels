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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `options` | `any` | yes | — | A collection to populate the select form control with. Can be a query recordset or an array of objects. |
| `selected` | `string` | no | — | Value of option that should be selected by default. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `multiple` | `boolean` | no | `false` | Whether to allow multiple selection of options in the select form control. |
| `valueField` | `string` | no | — | The column or property to use for the value of each list element. Used only when a query or array of objects has been supplied in the options argument. |
| `textField` | `string` | no | — | The column or property to use for the value of each list element that the end user will see. Used only when a query or array of objects has been supplied in the options argument. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>// Controller code
cities = model(&quot;city&quot;).findAll()&gt;

&lt;!--- View code---&gt;
#selectTag(name=&quot;cityId&quot;, options=cities)#

&lt;!--- Do this when CFWheels isn't grabbing the correct values for the `option`s' values and display texts---&gt;
#selectTag(name=&quot;cityId&quot;, options=cities, valueField=&quot;id&quot;, textField=&quot;name&quot;)#</pre>
