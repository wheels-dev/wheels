---
title: pluralize()
description: "Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the count argument."
sidebar:
  label: pluralize()
  order: 0
---

## Signature

`pluralize()` — returns `any`




## Description

Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the count argument.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `word` | `string` | yes | — | The word to pluralize. |
| `count` | `numeric` | yes | — | Pluralization will occur when this value is not 1. |
| `returnCount` | `boolean` | yes | — | Will return count prepended to the pluralization when true and count is not -1. |

## Examples

<pre>pluralize(word [, count, returnCount ]) &lt;!--- Pluralize a word, will result in &quot;people&quot; ---&gt;
#pluralize(&quot;person&quot;)#

&lt;!--- Pluralize based on the count passed in ---&gt;
Your search returned #pluralize(word=&quot;person&quot;, count=users.RecordCount)#</pre>
