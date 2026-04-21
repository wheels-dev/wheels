---
title: fileFieldTag()
description: "Builds and returns a string containing a file form control based on the supplied name."
sidebar:
  label: fileFieldTag()
  order: 0
---

## Signature

`fileFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a file form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage with label
#fileFieldTag(label=&quot;Upload Photo&quot;, name=&quot;photo&quot;)#

Output:

&lt;label for=&quot;photo&quot;&gt;Upload Photo&lt;/label&gt;
&lt;input type=&quot;file&quot; id=&quot;photo&quot; name=&quot;photo&quot;&gt;

2. With custom attributes
#fileFieldTag(
 label=&quot;Resume&quot;, 
 name=&quot;resume&quot;, 
 class=&quot;upload&quot;, 
 id=&quot;resume-upload&quot;, 
 accept=&quot;.pdf,.docx&quot;
)#

Adds CSS class, ID, and file type restrictions.

3. Label placement options
#fileFieldTag(label=&quot;Avatar&quot;, name=&quot;avatar&quot;, labelPlacement=&quot;before&quot;)#
#fileFieldTag(label=&quot;Attachment&quot;, name=&quot;attachment&quot;, labelPlacement=&quot;after&quot;)#

Moves the label before or after the &lt;input&gt; instead of wrapping.

4. Prepending/Appending markup
#fileFieldTag(
 label=&quot;Select File&quot;, 
 name=&quot;document&quot;, 
 prepend='&lt;div class=&quot;field-wrapper&quot;&gt;', 
 append='&lt;/div&gt;'
)#

Wraps the input inside a custom &lt;div&gt;.

5. Label customization with prepend/append
#fileFieldTag(
 label=&quot;Profile Photo&quot;, 
 name=&quot;profile&quot;, 
 prependToLabel='&lt;span class=&quot;required&quot;&gt;*&lt;/span&gt;', 
 appendToLabel=' &lt;small&gt;(max 2MB)&lt;/small&gt;'
)#
</code></pre>
