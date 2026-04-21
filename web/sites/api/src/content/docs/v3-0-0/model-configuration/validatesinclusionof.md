---
title: validatesInclusionOf()
description: "Ensures that a property’s value exists in a predefined list of allowed values. It is commonly used for dropdowns, radio buttons, or any scenario where only spec"
sidebar:
  label: validatesInclusionOf()
  order: 0
---

## Signature

`validatesInclusionOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Ensures that a property’s value exists in a predefined list of allowed values. It is commonly used for dropdowns, radio buttons, or any scenario where only specific values are acceptable.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `list` | `string` | yes | — | List of allowed values. |
| `message` | `string` | no | `[property] is not included in the list` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>1. Ensure that the user selects either &quot;Wheels&quot; or &quot;Rails&quot; as their framework
validatesInclusionOf(
    property=&quot;frameworkOfChoice&quot;,
    list=&quot;wheels,rails&quot;,
    message=&quot;Please try again, and this time, select a decent framework!&quot;
);

2. Validate multiple properties at once
validatesInclusionOf(
    properties=&quot;frameworkOfChoice,editorChoice&quot;,
    list=&quot;wheels,rails,vsCode,sublime&quot;,
    message=&quot;Invalid selection.&quot;
);

3. Only validate when creating a new object
validatesInclusionOf(
    property=&quot;subscriptionType&quot;,
    list=&quot;free,premium,enterprise&quot;,
    when=&quot;onCreate&quot;,
    message=&quot;You must choose a valid subscription type.&quot;
);

4. Skip validation if property is blank
validatesInclusionOf(
    property=&quot;preferredLanguage&quot;,
    list=&quot;cfml,python,javascript&quot;,
    allowBlank=true
);

5. Conditionally validate only for users in Europe
validatesInclusionOf(
    property=&quot;currency&quot;,
    list=&quot;EUR,GBP,CHF&quot;,
    condition=&quot;this.region eq 'Europe'&quot;,
    message=&quot;Invalid currency for European users.&quot;
);
</code></pre>
