---
title: addErrorToBase()
description: "Adds an error on the object as a whole (not tied to any specific property)."
sidebar:
  label: addErrorToBase()
  order: 0
---

## Signature

`addErrorToBase()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Adds an error on the object as a whole (not tied to any specific property).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | yes | — | The error message (such as "Please enter a correct name in the form field" for example). |
| `name` | `string` | no | — | A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that). |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a general error on the object (not tied to any single property)
user = model(&quot;User&quot;).findByKey(params.userId);
user.addErrorToBase(message=&quot;Your account has been locked. Please contact support.&quot;);

// 2. Add a named base error so it can be targeted or cleared later
order = model(&quot;Order&quot;).findByKey(params.orderId);
order.addErrorToBase(message=&quot;This order cannot be placed outside business hours.&quot;, name=&quot;businessHoursViolation&quot;);
if (order.hasErrors(name=&quot;businessHoursViolation&quot;)) {
    // handle the named error
}

// 3. Use addErrorToBase inside a custom validation method on the model
function validate() {
    if (this.totalAmount &gt; creditLimit()) {
        this.addErrorToBase(message=&quot;The total amount exceeds your available credit limit.&quot;);
    }
}
</code></pre>
