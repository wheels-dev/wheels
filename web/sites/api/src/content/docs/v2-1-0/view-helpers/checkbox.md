---
title: checkBox()
description: "Builds and returns a string containing a check box form control based on the supplied name."
sidebar:
  label: checkBox()
  order: 0
---

## Signature

`checkBox()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing a check box form control based on the supplied name.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out. |
| `checkedValue` | `string` | no | `1` |  |
| `uncheckedValue` | `string` | no | `0` | The value of the check box when it's on the unchecked state. |
| `label` | `string` | no | `useDefaultLabel` | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | `field-with-errors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- Basic example of a check box for a boolean field ---&gt;
#checkBox(objectName=&quot;photo&quot;, property=&quot;isPublic&quot;, label=&quot;Display this photo publicly.&quot;)#

&lt;!--- Shows check boxes for selecting public access for all photos provided by the `photos` association and nested properties ---&gt;
&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(user.photos)#&quot; index=&quot;i&quot;&gt;
    &lt;div&gt;
        &lt;h3&gt;#user.photos[i].title#:&lt;/h3&gt;
        &lt;div&gt;
            #checkBox(objectName=&quot;user&quot;, association=&quot;photos&quot;, position=i, property=&quot;isPublic&quot;, label=&quot;Display this photo publicly.&quot;)#
        &lt;/div&gt;
    &lt;/div&gt;
&lt;/cfloop&gt;</code></pre>
