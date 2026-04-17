---
title: endFormTag()
description: "Builds and returns a string containing the closing form tag."
sidebar:
  label: endFormTag()
  order: 0
---

## Signature

`endFormTag()` — returns `any`




## Description

Builds and returns a string containing the closing form tag.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `prepend` | `string` | yes | — | See documentation for textField |
| `append` | `string` | yes | — | See documentation for textField |

## Examples

<pre>&lt;!--- view code ---&gt;
		&lt;cfoutput&gt;
		    #startFormTag(action=&quot;create&quot;)#
		        &lt;!--- your form controls ---&gt;
		    #endFormTag()#
		&lt;/cfoutput&gt;</pre>
