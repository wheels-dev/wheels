---
title: automaticValidations()
description: "Whether or not to enable default validations for this model."
sidebar:
  label: automaticValidations()
  order: 0
---

## Signature

`automaticValidations()` — returns `any`




## Description

Whether or not to enable default validations for this model.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `boolean` | yes | — | Set to true or false. |

## Examples

<pre>// In `models/User.cfc`, disable automatic validations. In this case, automatic validations are probably enabled globally, but we want to disable just for this model.
&lt;cffunction name=&quot;init&quot;&gt;
	&lt;cfscript&gt;
		automaticValidations(false);
	&lt;/cfscript&gt;
&lt;/cffunction&gt;</pre>
