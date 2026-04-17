---
title: validatesPresenceOf()
description: "Ensures that the specified property (or properties) exists and is not blank. It is commonly used to enforce required fields before saving an object to the datab"
sidebar:
  label: validatesPresenceOf()
  order: 0
---

## Signature

`validatesPresenceOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Ensures that the specified property (or properties) exists and is not blank. It is commonly used to enforce required fields before saving an object to the database.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] can't be empty` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

## Examples

<pre><code class='javascript'>1. Ensure the `emailAddress` property is not blank
validatesPresenceOf(&quot;emailAddress&quot;);

2. Ensure multiple properties are present
validatesPresenceOf(&quot;firstName,lastName,emailAddress&quot;);

3. Use a custom error message for missing email
validatesPresenceOf(
    property=&quot;emailAddress&quot;,
    message=&quot;Email is required to create your account.&quot;
);

4. Validate only on create, not on update
validatesPresenceOf(
    properties=&quot;password&quot;,
    when=&quot;onCreate&quot;,
    message=&quot;Password is required when registering a new user.&quot;
);

5. Conditional validation based on a method
validatesPresenceOf(
    properties=&quot;discountCode&quot;,
    condition=&quot;this.isOnSale()&quot;,
    message=&quot;Discount code must be present for sale items.&quot;
);
</code></pre>
