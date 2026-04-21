---
title: validate()
description: "Used to register one or more validation methods that will be executed on a model object before it is saved to the database. This allows you to define custom val"
sidebar:
  label: validate()
  order: 0
---

## Signature

`validate()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Used to register one or more validation methods that will be executed on a model object before it is saved to the database. This allows you to define custom validation logic beyond the built-in validations like presence or uniqueness. You can also control when the validation runs (on create, update, or both) and under what conditions using condition and unless.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |
| `when` | `string` | no | `onSave` | Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`). |

</div>

## Examples

<pre><code class='javascript'>1. Register a method to validate objects before saving
function config() {
 validate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber() {
 // Make sure area code is '614'
 return Left(this.phoneNumber, 3) == &quot;614&quot;;
}

2. Register multiple validation methods
function config() {
 validate(&quot;checkPhoneNumber, checkEmailFormat&quot;);
}

function checkEmailFormat() {
 // Ensure email contains '@'
 return Find(&quot;@&quot;, this.email);
}

3. Conditional validation using `condition`
function config() {
 // Only validate phone numbers if the user is in the US
 validate(&quot;checkPhoneNumber&quot;, condition=&quot;this.country == 'US'&quot;);
}

4. Skip validation under certain conditions using `unless`
function config() {
 // Skip phone number validation if the user is a guest
 validate(&quot;checkPhoneNumber&quot;, unless=&quot;this.isGuest&quot;);
}

5. Run validation only on create or update
function config() {
 // Validate email only when creating a new record
 validate(&quot;checkEmailFormat&quot;, when=&quot;onCreate&quot;);

 // Validate password only on update
 validate(&quot;checkPasswordStrength&quot;, when=&quot;onUpdate&quot;);
}
</code></pre>
