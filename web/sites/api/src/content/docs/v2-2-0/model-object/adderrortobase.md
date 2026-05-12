---
title: addErrorToBase()
description: "Adds an error on a specific property."
sidebar:
  label: addErrorToBase()
  order: 0
---

## Signature

`addErrorToBase()` — returns `void`

**Available in:** `model`
**Category:** Error Functions

## Description

Adds an error on a specific property.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | yes | — | The error message (such as "Please enter a correct name in the form field" for example). |
| `name` | `string` | no | — | A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that). |

</div>

## Examples

<pre><code class='javascript'>// Add an error on the object that's not specific to a single property.
this.addErrorToBase(message=&quot;Your email address must be the same as your domain name.&quot;);
</code></pre>
