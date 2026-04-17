---
title: textAreaTag()
description: "Builds and returns an HTML <code>&lt;textarea&gt;</code> form control based only on the supplied field name, rather than being tied to a specific model object."
sidebar:
  label: textAreaTag()
  order: 0
---

## Signature

`textAreaTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns an HTML <code>&lt;textarea&gt;</code> form control based only on the supplied field name, rather than being tied to a specific model object. It is useful when you want to generate a standalone text area not bound to an object, such as for ad-hoc forms, search boxes, or generic input fields. You can set the initial content of the textarea, add a label, and pass in additional attributes like class, id, or rel. Options are also available to control label placement, prepend or append HTML wrappers, and configure whether output should be encoded for XSS protection.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `content` | `string` | no | — | Content to display in textarea on page load. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>1. Basic textarea with label
#textAreaTag(label=&quot;Description&quot;, name=&quot;description&quot;, content=params.description)#

2. Textarea with custom attributes
#textAreaTag(
 label=&quot;Notes&quot;, 
 name=&quot;notes&quot;, 
 class=&quot;form-control&quot;, 
 id=&quot;notesBox&quot;, 
 rows=&quot;6&quot;, 
 cols=&quot;60&quot;
)#

3. Textarea without label
#textAreaTag(name=&quot;feedback&quot;, content=&quot;Enter your feedback here...&quot;)#

4. Custom label placement
#textAreaTag(
 label=&quot;Comments&quot;, 
 name=&quot;comments&quot;, 
 labelPlacement=&quot;before&quot;
)#

5. Prepending and appending HTML
#textAreaTag(
 label=&quot;Message&quot;, 
 name=&quot;message&quot;, 
 prepend=&quot;&lt;div class='input-wrapper'&gt;&quot;, 
 append=&quot;&lt;/div&gt;&quot;
)#
</code></pre>
