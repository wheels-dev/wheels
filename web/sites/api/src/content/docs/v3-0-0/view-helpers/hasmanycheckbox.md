---
title: hasManyCheckBox()
description: "The hasManyCheckBox() helper generates the correct form elements for managing a hasMany or many-to-many association. It creates checkboxes for linking records t"
sidebar:
  label: hasManyCheckBox()
  order: 0
---

## Signature

`hasManyCheckBox()` — returns `string`

**Available in:** `controller`
**Category:** Form Association Functions

## Description

The hasManyCheckBox() helper generates the correct form elements for managing a hasMany or many-to-many association. It creates checkboxes for linking records together (e.g., a Book with many Authors).
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | Name of the variable containing the parent object to represent with this form field. |
| `association` | `string` | yes | — | Name of the association set in the parent object to represent with this form field. |
| `keys` | `string` | yes | — | Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | — | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using `aroundLeft` or `aroundRight`. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | — | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | — | The `class` name of the HTML tag that wraps the form control when there are errors. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage (Books -&gt; Authors)

// Loop through all authors and render checkboxes for associating them with the current book
&lt;cfloop query=&quot;authors&quot;&gt;
    #hasManyCheckBox(
        objectName=&quot;book&quot;,
        association=&quot;bookAuthors&quot;,
        keys=&quot;#book.key()#,#authors.id#&quot;,
        label=authors.fullName
    )#
&lt;/cfloop&gt;

2. Custom label placement

// Place the label after the checkbox instead of before
&lt;cfloop query=&quot;categories&quot;&gt;
    #hasManyCheckBox(
        objectName=&quot;post&quot;,
        association=&quot;postCategories&quot;,
        keys=&quot;#post.key()#,#categories.id#&quot;,
        label=categories.name,
        labelPlacement=&quot;after&quot;
    )#
&lt;/cfloop&gt;

3. Wrapping checkboxes in extra HTML (prepend/append)

// Use prepend and append to wrap checkboxes in a &lt;div&gt; with a custom class
&lt;cfloop query=&quot;tags&quot;&gt;
    #hasManyCheckBox(
        objectName=&quot;article&quot;,
        association=&quot;articleTags&quot;,
        keys=&quot;#article.key()#,#tags.id#&quot;,
        label=tags.name,
        prepend='&lt;div class=&quot;tag-option&quot;&gt;',
        append='&lt;/div&gt;'
    )#
&lt;/cfloop&gt;
</code></pre>
