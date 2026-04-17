---
title: radioButton()
description: "Generates an HTML radio button for a form, based on a model object’s property. It can handle simple properties as well as nested properties through associations"
sidebar:
  label: radioButton()
  order: 0
---

## Signature

`radioButton()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Generates an HTML radio button for a form, based on a model object’s property. It can handle simple properties as well as nested properties through associations, making it ideal for forms that work with both individual objects and collections. You can customize the radio button with additional attributes, labels, and error handling options. It automatically reflects the object’s current property value, so if the property matches the tagValue, the radio button will be marked as checked. This function helps you build dynamic forms safely and easily, with support for encoding to prevent XSS attacks, error highlighting, and custom HTML wrapping.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out. |
| `tagValue` | `string` | no | — | The value of the radio button when selected. |
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

<pre><code class='javascript'>1. Basic radio buttons for gender
&lt;cfoutput&gt;
&lt;fieldset&gt;
    &lt;legend&gt;Gender&lt;/legend&gt;
    #radioButton(objectName=&quot;user&quot;, property=&quot;gender&quot;, tagValue=&quot;m&quot;, label=&quot;Male&quot;)#&lt;br&gt;
    #radioButton(objectName=&quot;user&quot;, property=&quot;gender&quot;, tagValue=&quot;f&quot;, label=&quot;Female&quot;)#
&lt;/fieldset&gt;
&lt;/cfoutput&gt;

2. Radio buttons for nested association (committee members)
&lt;cfoutput&gt;
&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(committee.members)#&quot; index=&quot;i&quot;&gt;
    &lt;div&gt;
        &lt;h3&gt;#committee.members[i].fullName#:&lt;/h3&gt;
        &lt;div&gt;
            #radioButton(
                objectName=&quot;committee&quot;,
                association=&quot;members&quot;,
                position=i,
                property=&quot;gender&quot;,
                tagValue=&quot;m&quot;,
                label=&quot;Male&quot;
            )#&lt;br&gt;
            #radioButton(
                objectName=&quot;committee&quot;,
                association=&quot;members&quot;,
                position=i,
                property=&quot;gender&quot;,
                tagValue=&quot;f&quot;,
                label=&quot;Female&quot;
            )#
        &lt;/div&gt;
    &lt;/div&gt;
&lt;/cfloop&gt;
&lt;/cfoutput&gt;

3. Custom HTML wrapping and label placement
#radioButton(
    objectName=&quot;user&quot;,
    property=&quot;subscription&quot;,
    tagValue=&quot;premium&quot;,
    label=&quot;Premium Plan&quot;,
    prepend=&quot;&lt;div class='radio-wrapper'&gt;&quot;,
    append=&quot;&lt;/div&gt;&quot;,
    labelPlacement=&quot;aroundRight&quot;
)#
</code></pre>
