---
title: validateOnUpdate()
description: "Registers method(s) that should be called to validate existing objects before they are updated."
sidebar:
  label: validateOnUpdate()
  order: 0
---

## Signature

`validateOnUpdate()` — returns `any`




## Description

Registers method(s) that should be called to validate existing objects before they are updated.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for validate. |
| `condition` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `unless` | `string` | yes | — | See documentation for validatesConfirmationOf. |

</div>

## Examples

<pre>&lt;cffunction name=&quot;init&quot;&gt;
	&lt;cfscript&gt;
		// Register the `check` method below to be called to validate existing objects before they are updated
		validateOnUpdate(&quot;checkPhoneNumber&quot;);
	&lt;/cfscript&gt;
&lt;/cffunction&gt;

&lt;cffunction name=&quot;checkPhoneNumber&quot;&gt;
	&lt;cfscript&gt;
		// Make sure area code is `614`
		return Left(this.phoneNumber, 3) == &quot;614&quot;;
	&lt;/cfscript&gt;
&lt;/cffunction&gt;</pre>
