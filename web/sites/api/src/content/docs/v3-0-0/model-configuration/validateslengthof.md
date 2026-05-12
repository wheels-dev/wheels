---
title: validatesLengthOf()
description: "Validates that the value of the specified property matches the length requirements supplied."
sidebar:
  label: validatesLengthOf()
  order: 0
---

## Signature

`validatesLengthOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property matches the length requirements supplied.
Use the <code>exactly</code>, <code>maximum</code>, <code>minimum</code> and <code>within</code> arguments to specify the length requirements.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `message` | `string` | no | `[property] is the wrong length` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `exactly` | `numeric` | no | `0` | The exact length that the property value must be. |
| `maximum` | `numeric` | no | `0` | The maximum length that the property value can be. |
| `minimum` | `numeric` | no | `0` | The minimum length that the property value can be. |
| `within` | `string` | no | — | A list of two values (minimum and maximum) that the length of the property value must fall within. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>1. Ensure that `firstName` and `lastName` are no more than 50 characters
validatesLengthOf(
    properties=&quot;firstName,lastName&quot;,
    maximum=50,
    message=&quot;Please shorten your [property] please (50 characters max).&quot;
);

2. Ensure `password` is between 4 and 20 characters
validatesLengthOf(
    property=&quot;password&quot;,
    within=&quot;4,20&quot;,
    message=&quot;The password length must be between 4 and 20 characters.&quot;
);

3. Ensure `username` is exactly 8 characters
validatesLengthOf(
    property=&quot;username&quot;,
    exactly=8,
    message=&quot;Username must be exactly 8 characters.&quot;
);

4. Only validate if `region` is 'US'
validatesLengthOf(
    property=&quot;zipCode&quot;,
    exactly=5,
    condition=&quot;this.region eq 'US'&quot;,
    message=&quot;US zip codes must be exactly 5 digits.&quot;
);

5. Skip validation if property is blank
validatesLengthOf(
    property=&quot;nickname&quot;,
    maximum=15,
    allowBlank=true
);
</code></pre>
