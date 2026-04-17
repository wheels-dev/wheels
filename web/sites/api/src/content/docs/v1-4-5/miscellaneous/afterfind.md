---
title: afterFind()
description: "Registers method(s) that should be called after an existing object has been initialized (which is usually done with the findByKey or findOne method)."
sidebar:
  label: afterFind()
  order: 0
---

## Signature

`afterFind()` — returns `any`




## Description

Registers method(s) that should be called after an existing object has been initialized (which is usually done with the findByKey or findOne method).

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `methods` | `string` | yes | — | See documentation for afterNew. |

## Examples

<pre>&lt;!--- Instruct CFWheels to call the `setTime` method after getting objects or records with one of the finder methods ---&gt;
&lt;cffunction name=&quot;init&quot;&gt;
	&lt;cfset afterFind(&quot;setTime&quot;)&gt;
&lt;/cffunction&gt;

&lt;cffunction name=&quot;setTime&quot;&gt;
	&lt;cfset arguments.fetchedAt = Now()&gt;
	&lt;cfreturn arguments&gt;
&lt;/cffunction&gt;</pre>
