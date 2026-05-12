---
title: hasManyRadioButton()
description: "Used as a shortcut to output the proper form elements for an association. Note: Pass any additional arguments like class, rel, and id, and the generated tag wil"
sidebar:
  label: hasManyRadioButton()
  order: 0
---

## Signature

`hasManyRadioButton()` — returns `any`




## Description

Used as a shortcut to output the proper form elements for an association. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | Name of the variable containing the parent object to represent with this form field. |
| `association` | `string` | yes | — | Name of the association set in the parent object to represent with this form field. |
| `property` | `string` | yes | — | Name of the property in the child object to represent with this form field. |
| `keys` | `string` | yes | — | Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table. |
| `tagValue` | `string` | yes | — | The value of the radio button when selected. |
| `checkIfBlank` | `boolean` | yes | `false` | Whether or not to check this form field as a default if there is a blank value set for the property. |
| `label` | `string` | yes | — | The label text to use in the form control. |

</div>

## Examples

<pre>hasManyRadioButton(objectName, association, property, keys, tagValue [, checkIfBlank, label ]) &lt;!--- Show radio buttons for associating a default address with the current author ---&gt;
&lt;cfloop query=&quot;addresses&quot;&gt;
    #hasManyRadioButton(
        label=addresses.title,
        objectName=&quot;author&quot;,
        association=&quot;authorsDefaultAddresses&quot;,
        keys=&quot;#author.key()#,#addresses.id#&quot;
    )#
&lt;/cfloop&gt;</pre>
