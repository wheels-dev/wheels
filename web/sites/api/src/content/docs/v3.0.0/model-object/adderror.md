---
title: addError()
description: "Adds a custom error to a model instance. This is useful when built-in validations don’t fully cover your business rules, or when you want to enforce conditional"
sidebar:
  label: addError()
  order: 0
---

## Signature

`addError()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Adds a custom error to a model instance. This is useful when built-in validations don’t fully cover your business rules, or when you want to enforce conditional logic. The error will be attached to the given property and can later be retrieved using functions like errorsOn() or allErrors().



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | The name of the property you want to add an error on. |
| `message` | `string` | yes | — | The error message (such as "Please enter a correct name in the form field" for example). |
| `name` | `string` | no | — | A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that). |

## Examples

<pre><code class='javascript'>1. Add a simple error
// In app/models/User.cfc
this.addError(
    property=&quot;email&quot;,
    message=&quot;Sorry, you are not allowed to use that email. Try again, please.&quot;
);

Adds an error on the email property.

2. Add an error with a name identifier
this.addError(
    property=&quot;password&quot;,
    message=&quot;Password must contain at least one special character.&quot;,
    name=&quot;weakPassword&quot;
);

Adds a weakPassword error on the password property.
Later you can check for it:

if (user.hasError(&quot;password&quot;, &quot;weakPassword&quot;)) {
    // Handle specifically the weak password case
}

3. Adding multiple errors to the same property
this.addError(property=&quot;username&quot;, message=&quot;Username already taken.&quot;, name=&quot;duplicate&quot;);
this.addError(property=&quot;username&quot;, message=&quot;Username cannot contain spaces.&quot;, name=&quot;invalidChars&quot;);

Two different errors on username, each distinguished by their name.

4. Conditional custom errors
// Suppose only company emails are allowed
if (!listLast(this.email, &quot;@&quot;) == &quot;company.com&quot;) {
    this.addError(
        property=&quot;email&quot;,
        message=&quot;Please use your company email address.&quot;,
        name=&quot;invalidDomain&quot;
    );
}

Custom rule ensures only company domain emails are accepted.

5. Combine with built-in validations
// Inside a callback
function beforeSave() {
    if (this.age &lt; 18) {
        this.addError(property=&quot;age&quot;, message=&quot;You must be at least 18 years old.&quot;);
    }
}

Even though validatesPresenceOf(&quot;age&quot;) might exist, addError() gives you extra conditional control.</code></pre>
