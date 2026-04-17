---
title: hasProperty()
description: "Checks if a given property exists on a model object. It’s useful for safely validating whether a field is defined before accessing it, especially in dynamic cod"
sidebar:
  label: hasProperty()
  order: 0
---

## Signature

`hasProperty()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Checks if a given property exists on a model object. It’s useful for safely validating whether a field is defined before accessing it, especially in dynamic code or when working with user input. This method also provides dynamic helpers (e.g., object.hasEmail()) for convenience.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

## Examples

<pre><code class='javascript'>1. Basic usage with existing property
employee = model(&quot;employee&quot;).new();
employee.firstName = &quot;Alice&quot;;

writeOutput(employee.hasProperty(&quot;firstName&quot;)); // true

2. Checking a property that does not exist
employee = model(&quot;employee&quot;).new();

writeOutput(employee.hasProperty(&quot;middleName&quot;)); // false

3. Using the dynamic helper
employee = model(&quot;employee&quot;).new();
employee.email = &quot;alice@example.com&quot;;

// Equivalent to hasProperty(&quot;email&quot;)
if (employee.hasEmail()) {
    writeOutput(&quot;Email property exists!&quot;);
}

4. Before using a property safely
user = model(&quot;user&quot;).findByKey(1);

// Avoid runtime errors by checking
if (user.hasProperty(&quot;phoneNumber&quot;)) {
    writeOutput(user.phoneNumber);
} else {
    writeOutput(&quot;No phone number property defined.&quot;);
}
</code></pre>
