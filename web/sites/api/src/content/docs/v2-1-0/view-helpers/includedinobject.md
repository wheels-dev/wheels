---
title: includedInObject()
description: "Used as a shortcut to check if the specified IDs are a part of the main form object."
sidebar:
  label: includedInObject()
  order: 0
---

## Signature

`includedInObject()` — returns `boolean`

**Available in:** `controller`
**Category:** Form Association Functions

## Description

Used as a shortcut to check if the specified IDs are a part of the main form object.
This method should only be used for <code>hasMany</code> associations.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | Name of the variable containing the parent object to represent with this form field. |
| `association` | `string` | yes | — | Name of the association set in the parent object to represent with this form field. |
| `keys` | `string` | yes | — | Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table. |

</div>

## Examples

<pre><code class='javascript'>// Check to see if the customer is subscribed to the Swimsuit Edition. Note that the order of the `keys` argument should match the order of the `customerid` and `publicationid` columns in the `subscriptions` join table
if(!includedInObject(objectName=&quot;customer&quot;, association=&quot;subscriptions&quot;, keys=&quot;#customer.key()#,#swimsuitEdition.id#&quot;)){
    assignSalesman(customer);
}</code></pre>
