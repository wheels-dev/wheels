---
title: addErrorToBase()
description: "Adds an error on a specific property."
sidebar:
  label: addErrorToBase()
  order: 0
---

## Signature

`addErrorToBase()` — returns `any`




## Description

Adds an error on a specific property.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | yes | — | The error message (such as "Please enter a correct name in the form field" for example). |
| `name` | `string` | yes | — | A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that). |

## Examples

<pre>Adds an error on the object as a whole (not related to any specific property). &lt;!--- Add an error on the object ---&gt;
&lt;cfset this.addErrorToBase(message=&quot;Your email address must be the same as your domain name.&quot;)&gt;</pre>
