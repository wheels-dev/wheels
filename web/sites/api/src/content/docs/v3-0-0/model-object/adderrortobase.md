---
title: addErrorToBase()
description: "Adds an error directly on the model object itself, not tied to a specific property. This is useful when the error applies to the object as a whole or to a combi"
sidebar:
  label: addErrorToBase()
  order: 0
---

## Signature

`addErrorToBase()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Adds an error directly on the model object itself, not tied to a specific property. This is useful when the error applies to the object as a whole or to a combination of properties, rather than a single field (for example: comparing two values, enforcing cross-property business rules, or validating external conditions).



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | yes | — | The error message (such as "Please enter a correct name in the form field" for example). |
| `name` | `string` | no | — | A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that). |

## Examples

<pre><code class='javascript'>1. Add a general error
this.addErrorToBase(
    message=&quot;Your email address must be the same as your domain name.&quot;
);

Error applies to the whole object, not just email.

2. Add a named error
this.addErrorToBase(
    message=&quot;Order total must be greater than zero.&quot;,
    name=&quot;invalidTotal&quot;
);

Useful for distinguishing this error later when multiple base errors exist.

3. Enforce a cross-property rule
if (this.startDate &gt; this.endDate) {
    this.addErrorToBase(
        message=&quot;Start date cannot be after end date.&quot;,
        name=&quot;invalidDateRange&quot;
    );
}

Rule depends on two properties, so the error belongs on the object as a whole.

4. Business logic validation
if (this.balance &lt; this.minimumDeposit) {
    this.addErrorToBase(
        message=&quot;Balance is below the required minimum deposit.&quot;,
        name=&quot;lowBalance&quot;
    );
}

Example where validation involves external business rules, not just a single column.

5. Using with valid()
if (!user.valid()) {
    writeDump(user.allErrors());
    // Will include base-level errors from addErrorToBase()
}</code></pre>
