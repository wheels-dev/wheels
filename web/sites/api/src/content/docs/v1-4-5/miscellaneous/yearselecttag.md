---
title: yearSelectTag()
description: "Builds and returns a string containing a select form control for a range of years based on the supplied name."
sidebar:
  label: yearSelectTag()
  order: 0
---

## Signature

`yearSelectTag()` — returns `any`




## Description

Builds and returns a string containing a select form control for a range of years based on the supplied name.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `selected` | `string` | yes | — | The year that should be selected initially. |
| `startYear` | `numeric` | yes | `2010` | See documentation for dateSelect. |
| `endYear` | `numeric` | yes | `2020` | See documentation for dateSelect. |
| `includeBlank` | `any` | yes | `false` | See documentation for select. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

## Examples

<pre>&lt;!--- View code ---&gt;
&lt;cfoutput&gt;
    #yearSelectTag(name=&quot;yearOfBirthday&quot;, selected=params.yearOfBirthday)#
&lt;/cfoutput&gt;

&lt;!--- Only allow selection of year to be for the past 50 years, minimum being 18 years ago ---&gt;
&lt;cfset fiftyYearsAgo = Now() - 50&gt;
&lt;cfset eighteenYearsAgo = Now() - 18&gt;
&lt;cfoutput&gt;
	#yearSelectTag(name=&quot;yearOfBirthday&quot;, selected=params.yearOfBirthday, startYear=fiftyYearsAgo, endYear=eighteenYearsAgo)#
&lt;/cfoutput&gt;</pre>
