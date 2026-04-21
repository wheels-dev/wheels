---
title: hasManyCheckBox()
description: "Used as a shortcut to output the proper form elements for an association. Note: Pass any additional arguments like class, rel, and id, and the generated tag wil"
sidebar:
  label: hasManyCheckBox()
  order: 0
---

## Signature

`hasManyCheckBox()` — returns `any`




## Description

Used as a shortcut to output the proper form elements for an association. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | Name of the variable containing the parent object to represent with this form field. |
| `association` | `string` | yes | — | Name of the association set in the parent object to represent with this form field. |
| `keys` | `string` | yes | — | Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table. |
| `label` | `string` | yes | — | The label text to use in the form control. |
| `labelPlacement` | `string` | yes | — | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | yes | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | yes | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | yes | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | yes | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | yes | — | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | yes | — | The class name of the HTML tag that wraps the form control when there are errors. |

</div>

## Examples

<pre>hasManyCheckBox(objectName, association, keys [, label, labelPlacement, prepend, append, prependToLabel, appendToLabel, errorElement, errorClass ]) &lt;!--- Show check boxes for associating authors with the current book ---&gt;
&lt;cfloop query=&quot;authors&quot;&gt;
    #hasManyCheckBox(
        label=authors.fullName,
        objectName=&quot;book&quot;,
        association=&quot;bookAuthors&quot;,
        keys=&quot;#book.key()#,#authors.id#&quot;
    )#
&lt;/cfloop&gt;</pre>
