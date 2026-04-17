---
title: includeLayout()
description: "Includes the contents of another layout file. Typically used when a child layout wants to include a parent layout, or to nest layouts for consistent site struct"
sidebar:
  label: includeLayout()
  order: 0
---

## Signature

`includeLayout()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Includes the contents of another layout file. Typically used when a child layout wants to include a parent layout, or to nest layouts for consistent site structure.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `layout` | Name of the layout file to include. |

## Examples

<pre><code class='javascript'>1. Make sure that the `sidebar` value is provided for the parent layout
&lt;cfsavecontent variable=&quot;categoriesSidebar&quot;&gt;
	&lt;cfoutput&gt;
		&lt;ul&gt;
			#includePartial(categories)#
		&lt;/ul&gt;
	&lt;/cfoutput&gt;
&lt;/cfsavecontent&gt;
contentFor(sidebar=categoriesSidebar);

// Include parent layout at `app/views/layout.cfm`
#includeLayout(&quot;/layout.cfm&quot;)#</code></pre>
