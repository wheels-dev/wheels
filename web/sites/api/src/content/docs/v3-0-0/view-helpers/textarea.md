---
title: textArea()
description: "Builds and returns an HTML <code>&lt;textarea&gt;</code> form control for a given model object and property. It is commonly used when you need a larger text inp"
sidebar:
  label: textArea()
  order: 0
---

## Signature

`textArea()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns an HTML <code>&lt;textarea&gt;</code> form control for a given model object and property. It is commonly used when you need a larger text input field, such as for descriptions, comments, or notes. The function automatically binds the value of the specified property from the object to the textarea. You can also pass additional attributes like class, id, or rel to customize the generated HTML. When working with nested forms or associations, you can specify the association and position arguments to bind the field to related objects. Wheels also provides options to add labels, control label placement, prepend or append HTML around the field, and handle error display automatically.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out. |
| `label` | `string` | no | `useDefaultLabel` | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | `field-with-errors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic textarea with label
#textArea(label=&quot;Overview&quot;, objectName=&quot;article&quot;, property=&quot;overview&quot;)#

2. Customizing with HTML attributes
#textArea(
 label=&quot;Comments&quot;, 
 objectName=&quot;post&quot;, 
 property=&quot;comments&quot;, 
 class=&quot;form-control&quot;, 
 id=&quot;commentsBox&quot;, 
 rows=&quot;5&quot;, 
 cols=&quot;50&quot;
)#

3. Using with nested associations
&lt;fieldset&gt;
 &lt;legend&gt;Screenshots&lt;/legend&gt;
 &lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(site.screenshots)#&quot; index=&quot;i&quot;&gt;
 #fileField(label=&quot;File #i#&quot;, objectName=&quot;site&quot;, association=&quot;screenshots&quot;, position=i, property=&quot;file&quot;)#
 #textArea(label=&quot;Caption #i#&quot;, objectName=&quot;site&quot;, association=&quot;screenshots&quot;, position=i, property=&quot;caption&quot;)#
 &lt;/cfloop&gt;
&lt;/fieldset&gt;

4. Controlling label placement
#textArea(
 label=&quot;Details&quot;, 
 objectName=&quot;project&quot;, 
 property=&quot;details&quot;, 
 labelPlacement=&quot;before&quot;
)#

5. Prepending and appending HTML
#textArea(
 label=&quot;Notes&quot;, 
 objectName=&quot;task&quot;, 
 property=&quot;notes&quot;, 
 prepend=&quot;&lt;div class='input-wrapper'&gt;&quot;, 
 append=&quot;&lt;/div&gt;&quot;
)#

6. Handling validation errors
#textArea(
 label=&quot;Description&quot;, 
 objectName=&quot;product&quot;, 
 property=&quot;description&quot;, 
 errorElement=&quot;div&quot;, 
 errorClass=&quot;input-error&quot;
)#
</code></pre>
