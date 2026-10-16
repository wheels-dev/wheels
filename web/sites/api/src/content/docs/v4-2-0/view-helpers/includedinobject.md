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

<pre><code class='javascript'>// 1. Check whether a customer is already subscribed to a particular publication via a hasMany join
// (Note: keys should be listed in the order they appear in the join table columns)
if (includedInObject(objectName=&quot;customer&quot;, association=&quot;subscriptions&quot;, keys=&quot;#customer.key()#,#swimsuitEdition.id#&quot;)) {
    writeOutput(&quot;Already subscribed.&quot;);
} else {
    writeOutput(&quot;Not yet subscribed.&quot;);
}

// 2. Use the return value to find the position of the associated object in the array
position = includedInObject(objectName=&quot;order&quot;, association=&quot;lineItems&quot;, keys=&quot;#lineItem.key()#&quot;);
// Returns false when not found, or the 1-based index position when found
// position -&gt; 3 (the associated lineItem is at index 3 in order.lineItems)

// 3. Guard against adding duplicate associations before creating a new join record
if (!includedInObject(objectName=&quot;student&quot;, association=&quot;courses&quot;, keys=&quot;#course.key()#&quot;)) {
    student.courses = ArrayAppend(student.courses, course);
}
</code></pre>
