---
title: validateOnCreate()
description: "Registers method(s) that should be called to validate new objects before they are inserted."
sidebar:
  label: validateOnCreate()
  order: 0
---

## Signature

`validateOnCreate()` — returns `any`




## Description

Registers method(s) that should be called to validate new objects before they are inserted.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for validate. |
| `condition` | `string` | yes | — | See documentation for validatesConfirmationOf. |
| `unless` | `string` | yes | — | See documentation for validatesConfirmationOf. |

## Examples

<pre>&lt;cffunction name=&quot;init&quot;&gt;
	&lt;cfscript&gt;
		// Register the `checkPhoneNumber` method below to be called to validate new objects before they are inserted
		validateOnCreate(&quot;checkPhoneNumber&quot;);
	&lt;/cfscript&gt;
&lt;/cffunction&gt;

&lt;cffunction name=&quot;checkPhoneNumber&quot;&gt;
	&lt;cfscript&gt;
		// Make sure area code is `614`
		return Left(this.phoneNumber, 3) == &quot;614&quot;;
	&lt;/cfscript&gt;
&lt;/cffunction&gt;</pre>
