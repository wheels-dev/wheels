---
title: addError()
description: "Adds an error on a specific property."
sidebar:
  label: addError()
  order: 0
---

## Signature

`addError()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Adds an error on a specific property.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | The name of the property you want to add an error on. |
| `message` | `string` | yes | — | The error message (such as "Please enter a correct name in the form field" for example). |
| `name` | `string` | no | — | A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that). |

</div>

## Examples

<pre><code class='javascript'>// 1. Add an error to the `email` property.
this.addError(property=&quot;email&quot;, message=&quot;Sorry, you are not allowed to use that email. Try again, please.&quot;);

// 2. Add a named error so you can distinguish it from other errors on the same property.
this.addError(property=&quot;email&quot;, message=&quot;That email address is already taken.&quot;, name=&quot;emailTaken&quot;);

// 3. Check for the named error after adding it.
this.addError(property=&quot;username&quot;, message=&quot;Username is reserved.&quot;, name=&quot;reservedUsername&quot;);
if (this.hasErrors(property=&quot;username&quot;, name=&quot;reservedUsername&quot;)) {
	writeOutput(&quot;A reserved-username error is present.&quot;);
}
</code></pre>
