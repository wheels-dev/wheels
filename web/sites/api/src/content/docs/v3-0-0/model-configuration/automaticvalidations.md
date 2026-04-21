---
title: automaticValidations()
description: "Controls whether automatic validations should be enabled for a specific model. By default, Wheels can automatically infer validations from your database schema"
sidebar:
  label: automaticValidations()
  order: 0
---

## Signature

`automaticValidations()` — returns `void`

**Available in:** `model`
**Category:** Validation Functions

## Description

Controls whether automatic validations should be enabled for a specific model. By default, Wheels can automatically infer validations from your database schema (e.g., NOT NULL fields, field length limits, etc.). This function lets you override that behavior at the model level — enabling or disabling automatic validations regardless of the global setting.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `boolean` | yes | — | Set to `true` or `false`. |

</div>

## Examples

<pre><code class='javascript'>1. Disable automatic validations for a single model
component extends="Model" {
    function config() {
        automaticValidations(false);
    }
}


Useful when automatic validations are enabled globally but a model requires custom validation handling.

2. Enable automatic validations explicitly for a model
component extends="Model" {
    function config() {
        automaticValidations(true);
    }
}


Ensures this model always applies database-inferred validations, even if global automatic validations are turned off.

3. Combining with custom validations
component extends="Model" {
    function config() {
        automaticValidations(false); // turn off inferred rules
        validatesPresenceOf("email");
        validatesFormatOf(property="email", regex="^[\w\.-]+@[\w\.-]+\.\w+$");
    }
}


Here, automatic validations are disabled, but explicit validation rules are still applied.</code></pre>
