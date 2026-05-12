---
title: validateOnUpdate()
description: "Registers one or more validation methods that will be executed only when an existing object is being updated in the database. This allows you to enforce rules t"
sidebar:
  label: validateOnUpdate()
  order: 0
---

## Signature

`validateOnUpdate()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Registers one or more validation methods that will be executed only when an existing object is being updated in the database. This allows you to enforce rules that apply strictly to updates, without affecting the creation of new records. You can also control whether the validation runs using the condition and unless arguments.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | no | — | Method name or list of method names to call. Can also be called with the `method` argument. |
| `condition` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run). |
| `unless` | `string` | no | — | String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run). |

</div>

## Examples

<pre><code class='javascript'>1. Basic usage: validate existing objects before update
function config() {
 validateOnUpdate(&quot;checkPhoneNumber&quot;);
}

function checkPhoneNumber() {
 // Ensure area code is '614'
 return Left(this.phoneNumber, 3) == &quot;614&quot;;
}

2. Register multiple methods for validation on update
function config() {
 validateOnUpdate(&quot;checkPhoneNumber, checkEmailFormat&quot;);
}

function checkEmailFormat() {
 // Ensure email contains '@'
 return Find(&quot;@&quot;, this.email);
}

3. Conditional validation using `condition`
function config() {
 // Only validate phone number if the country is US
 validateOnUpdate(&quot;checkPhoneNumber&quot;, condition=&quot;this.country == 'US'&quot;);
}

4. Skip validation under certain conditions using `unless`
function config() {
 // Skip phone number validation if the user is an admin
 validateOnUpdate(&quot;checkPhoneNumber&quot;, unless=&quot;this.isAdmin&quot;);
}
</code></pre>
