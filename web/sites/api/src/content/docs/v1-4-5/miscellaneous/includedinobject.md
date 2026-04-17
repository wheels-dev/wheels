---
title: includedInObject()
description: "Used as a shortcut to check if the specified IDs are a part of the main form object. This method should only be used for hasMany associations."
sidebar:
  label: includedInObject()
  order: 0
---

## Signature

`includedInObject()` — returns `any`




## Description

Used as a shortcut to check if the specified IDs are a part of the main form object. This method should only be used for hasMany associations.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `string` | yes | — | Name of the variable containing the parent object to represent with this form field. |
| `association` | `string` | yes | — | Name of the association set in the parent object to represent with this form field. |
| `keys` | `string` | yes | — | Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table. |

## Examples

<pre>includedInObject(objectName, association, keys) &lt;!--- Check to see if the customer is subscribed to the Swimsuit Edition. Note that the order of the `keys` argument should match the order of the `customerid` and `publicationid` columns in the `subscriptions` join table ---&gt;
&lt;cfif not includedInObject(objectName=&quot;customer&quot;, association=&quot;subscriptions&quot;, keys=&quot;#customer.key()#,#swimsuitEdition.id#&quot;)&gt;
    &lt;cfset assignSalesman(customer)&gt;
&lt;/cfif&gt;</pre>
