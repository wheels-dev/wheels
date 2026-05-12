---
title: hasManyRadioButton()
description: "This helper generates radio buttons for managing a hasMany or one-to-many association, where you want the user to pick one option (e.g., default address, primar"
sidebar:
  label: hasManyRadioButton()
  order: 0
---

## Signature

`hasManyRadioButton()` — returns `string`

**Available in:** `controller`
**Category:** Form Association Functions

## Description

This helper generates radio buttons for managing a hasMany or one-to-many association, where you want the user to pick one option (e.g., default address, primary contact method, preferred category).
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | Name of the variable containing the parent object to represent with this form field. |
| `association` | `string` | yes | — | Name of the association set in the parent object to represent with this form field. |
| `property` | `string` | yes | — | Name of the property in the child object to represent with this form field. |
| `keys` | `string` | yes | — | Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table. |
| `tagValue` | `string` | yes | — | The value of the radio button when selected. |
| `checkIfBlank` | `boolean` | no | `false` | Whether or not to check this form field as a default if there is a blank value set for the property. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage (Author -&gt; Default Address)

// Pick one address as the author’s default
&lt;cfloop query=&quot;addresses&quot;&gt;
    #hasManyRadioButton(
        objectName=&quot;author&quot;,
        association=&quot;authorsDefaultAddresses&quot;,
        property=&quot;defaultAddressId&quot;,
        keys=&quot;#author.key()#,#addresses.id#&quot;,
        tagValue=&quot;#addresses.id#&quot;,
        label=addresses.title
    )#
&lt;/cfloop&gt;

2. Pre-check default radio if property is blank

// If no address is selected yet, pre-check the &quot;Home&quot; option
&lt;cfloop query=&quot;addresses&quot;&gt;
    #hasManyRadioButton(
        objectName=&quot;author&quot;,
        association=&quot;authorsDefaultAddresses&quot;,
        property=&quot;defaultAddressId&quot;,
        keys=&quot;#author.key()#,#addresses.id#&quot;,
        tagValue=&quot;#addresses.id#&quot;,
        label=addresses.title,
        checkIfBlank=(addresses.title EQ &quot;Home&quot;)
    )#
&lt;/cfloop&gt;

3. Style with extra HTML attributes

// Add class and id for custom styling
&lt;cfloop query=&quot;paymentMethods&quot;&gt;
    #hasManyRadioButton(
        objectName=&quot;user&quot;,
        association=&quot;userPaymentMethods&quot;,
        property=&quot;defaultPaymentMethodId&quot;,
        keys=&quot;#user.key()#,#paymentMethods.id#&quot;,
        tagValue=&quot;#paymentMethods.id#&quot;,
        label=paymentMethods.name,
        class=&quot;radio-option&quot;,
        id=&quot;paymentMethod_#paymentMethods.id#&quot;
    )#
&lt;/cfloop&gt;
</code></pre>
