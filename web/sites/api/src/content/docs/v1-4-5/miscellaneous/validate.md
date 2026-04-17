---
title: validate()
description: "Registers method(s) that should be called to validate objects before they are saved."
sidebar:
  label: validate()
  order: 0
---

## Signature

`validate()` — returns `any`




## Description

Registers method(s) that should be called to validate objects before they are saved.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | Method name or list of method names to call. (Can also be called with the method argument.) |
| `condition` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `unless` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `when` | `string` | yes | `onSave` | See documentation for validatesConfirmationOf. |

## Examples

<pre>&lt;cffunction name=&quot;init&quot;&gt;
	&lt;cfscript&gt;
		// Register the `checkPhoneNumber` method below to be called to validate objects before they are saved
		validate(&quot;checkPhoneNumber&quot;);
	&lt;/cfscript&gt;
&lt;/cffunction&gt;

&lt;cffunction name=&quot;checkPhoneNumber&quot;&gt;
	&lt;cfscript&gt;
		// Make sure area code is `614`
		return Left(this.phoneNumber, 3) == &quot;614&quot;;
	&lt;/cfscript&gt;
&lt;/cffunction&gt;</pre>
