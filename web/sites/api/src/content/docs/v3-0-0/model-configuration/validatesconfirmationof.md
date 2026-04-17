---
title: validatesConfirmationOf()
description: "Validates that the value of the specified property also has an identical confirmation value."
sidebar:
  label: validatesConfirmationOf()
  order: 0
---

## Signature

`validatesConfirmationOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property also has an identical confirmation value.
This is common when having a user type in their email address a second time to confirm, confirming a password by typing it a second time, etc.
The confirmation value only exists temporarily and never gets saved to the database.
By convention, the confirmation property has to be named the same as the property with "Confirmation" appended at the end.
Using the password example, to confirm our password property, we would create a property called <code>passwordConfirmation</code>.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] should match confirmation` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |
| `caseSensitive` | `boolean` | no | `false` | Ensure the confirmed property comparison is case sensitive |

## Examples

<pre><code class='javascript'>1. Validate password confirmation on user creation
validatesConfirmationOf(
    property=&quot;password&quot;,
    when=&quot;onCreate&quot;,
    message=&quot;Your password and its confirmation do not match. Please try again.&quot;
);

2. Validate multiple fields at once: password and email
validatesConfirmationOf(
    properties=&quot;password,email&quot;,
    when=&quot;onCreate&quot;,
    message=&quot;Fields must match their confirmation.&quot;
);

3. Case-sensitive validation
validatesConfirmationOf(
    property=&quot;password&quot;,
    caseSensitive=true,
    message=&quot;Password and confirmation must match exactly, including case.&quot;
);

4. Conditional validation using `condition`
validatesConfirmationOf(
    property=&quot;email&quot;,
    condition=&quot;this.isNewsletterSubscriber&quot;,
    message=&quot;Email confirmation required for newsletter subscription.&quot;
);

5. Skip validation for admin users using `unless`
validatesConfirmationOf(
    property=&quot;password&quot;,
    unless=&quot;this.isAdmin&quot;,
    message=&quot;Admins do not need to confirm their password.&quot;
);
</code></pre>
