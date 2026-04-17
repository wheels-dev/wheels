---
title: includeLayout()
description: "Includes the contents of another layout file."
sidebar:
  label: includeLayout()
  order: 0
---

## Signature

`includeLayout()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Includes the contents of another layout file.
This is usually used to include a parent layout from within a child layout.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `layout` | Name of the layout file to include. |

## Examples

<pre><code class='javascript'>&lt;!--- Make sure that the `sidebar` value is provided for the parent layout ---&gt;
&lt;cfsavecontent variable=&quot;categoriesSidebar&quot;&gt;
	&lt;cfoutput&gt;
		&lt;ul&gt;
			#includePartial(categories)#
		&lt;/ul&gt;
	&lt;/cfoutput&gt;
&lt;/cfsavecontent&gt;
contentFor(sidebar=categoriesSidebar);

&lt;!---Include parent layout at `views/layout.cfm`---&gt;
#includeLayout(&quot;/layout.cfm&quot;)#</code></pre>
