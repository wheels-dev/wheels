---
title: passwordField()
description: "Builds and returns a string containing a password field form control based on the supplied objectName and property."
sidebar:
  label: passwordField()
  order: 0
---

## Signature

`passwordField()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing a password field form control based on the supplied objectName and property.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



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

<pre><code class='javascript'>1. Basic Password Field
&lt;cfoutput&gt;
    #passwordField(label=&quot;Password&quot;, objectName=&quot;user&quot;, property=&quot;password&quot;)#
&lt;/cfoutput&gt;

2. Password Field for a Nested Association
&lt;fieldset&gt;
    &lt;legend&gt;Passwords&lt;/legend&gt;
    &lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(user.passwords)#&quot; index=&quot;i&quot;&gt;
        #passwordField(
            label=&quot;Password ##i#&quot;, 
            objectName=&quot;user&quot;, 
            association=&quot;passwords&quot;, 
            position=i, 
            property=&quot;password&quot;
        )#
    &lt;/cfloop&gt;
&lt;/fieldset&gt;

3. Custom Label Placement and Error Handling
&lt;cfoutput&gt;
    #passwordField(
        label=&quot;Enter Your Password&quot;,
        objectName=&quot;user&quot;,
        property=&quot;password&quot;,
        labelPlacement=&quot;before&quot;,
        errorClass=&quot;input-error&quot;,
        prepend=&quot;&lt;div class='input-group'&gt;&quot;,
        append=&quot;&lt;/div&gt;&quot;
    )#
&lt;/cfoutput&gt;
</code></pre>
