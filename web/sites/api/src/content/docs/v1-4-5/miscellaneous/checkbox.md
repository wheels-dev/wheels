---
title: checkBox()
description: "Builds and returns a string containing a check box form control based on the supplied objectName and property. In most cases, this function generates a form fie"
sidebar:
  label: checkBox()
  order: 0
---

## Signature

`checkBox()` — returns `any`




## Description

Builds and returns a string containing a check box form control based on the supplied objectName and property. In most cases, this function generates a form field that should represent a boolean style field in your data. Use checkBoxTag() or hasManyCheckBox() to generate check boxes for selecting multiple values. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | yes | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out. |
| `position` | `string` | yes | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out. |
| `checkedValue` | `string` | yes | `1` | The value of the check box when it's in the checked state. |
| `uncheckedValue` | `string` | yes | `0` | The value of the check box when it's in the unchecked state. |
| `label` | `string` | yes | `useDefaultLabel` | The label text to use in the form control. |
| `labelPlacement` | `string` | yes | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | yes | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | yes | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | yes | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | yes | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | yes | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | yes | `fieldWithErrors` | The class name of the HTML tag that wraps the form control when there are errors. |

</div>

## Examples

<pre>checkBox(objectName, property [, association, position, checkedValue, uncheckedValue, label, labelPlacement, prepend, append, prependToLabel, appendToLabel, errorElement, errorClass ]) &lt;!--- Basic example of a check box for a boolean field ---&gt;
&lt;cfoutput&gt;
    #checkBox(objectName=&quot;photo&quot;, property=&quot;isPublic&quot;, label=&quot;Display this photo publicly.&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Shows check boxes for selecting public access for all photos provided by the `photos` association and nested properties ---&gt;
&lt;cfoutput&gt;
    &lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(user.photos)#&quot; index=&quot;i&quot;&gt;
        &lt;div&gt;
            &lt;h3&gt;#user.photos[i].title#:&lt;/h3&gt;
            &lt;div&gt;
                #checkBox(objectName=&quot;user&quot;, association=&quot;photos&quot;, position=i, property=&quot;isPublic&quot;, label=&quot;Display this photo publicly.&quot;)#
            &lt;/div&gt;
        &lt;/div&gt;
    &lt;/cfloop&gt;
&lt;/cfoutput&gt;</pre>
