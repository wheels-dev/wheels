---
title: validatesFormatOf()
description: "Validates that the value of the specified property is formatted correctly by matching it against a regular expression using the regEx argument and / or against"
sidebar:
  label: validatesFormatOf()
  order: 0
---

## Signature

`validatesFormatOf()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Validates that the value of the specified property is formatted correctly by matching it against a regular expression using the regEx argument and / or against a built-in CFML validation type using the type argument (creditcard, date, email, etc.).



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `string` | no | — | Name of property or list of property names to validate against (can also be called with the `property` argument). |
| `regEx` | `string` | no | — | Regular expression to verify against. |
| `type` | `string` | no | — | One of the following types to verify against: creditcard, date, email, eurodate, guid, social_security_number, ssn, telephone, time, URL, USdate, UUID, variableName, zipcode (will be passed through to your CFML engine's IsValid() function). |
| `message` | `string` | no | `[property] is invalid` | Supply a custom error message here to override the built-in one. |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |
| `allowBlank` | `boolean` | no | `false` | If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

## Examples

<pre>// Make sure that the user has entered a correct credit card validatesFormatOf(property=&quot;cc&quot;, type=&quot;creditcard&quot;); /*  * Make sure that the user has entered an email address ending with the  * `.se` domain when the `ipCheck()` method returns `true`, and it's not  * Sunday. Also supply a custom error message that overrides the CFWheels  * default one  */ validatesFormatOf( property=&quot;email&quot;, regEx=&quot;^.*@.*\.se$&quot;, condition=&quot;ipCheck()&quot;, unless=&quot;DayOfWeek() eq 1&quot; message=&quot;Sorry, you must have a Swedish email address to use this website.&quot; );</pre>
