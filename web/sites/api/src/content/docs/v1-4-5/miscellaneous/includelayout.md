---
title: includeLayout()
description: "Includes the contents of another layout file. This is usually used to include a parent layout from within a child layout."
sidebar:
  label: includeLayout()
  order: 0
---

## Signature

`includeLayout()` — returns `any`




## Description

Includes the contents of another layout file. This is usually used to include a parent layout from within a child layout.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | `layout` | Name of the layout file to include. |

</div>

## Examples

<pre>&lt;!--- Make sure that the `sidebar` value is provided for the parent layout ---&gt;
&lt;cfsavecontent variable=&quot;categoriesSidebar&quot;&gt;
	&lt;cfoutput&gt;
		&lt;ul&gt;
			##includePartial(categories)##
		&lt;/ul&gt;
	&lt;/cfoutput&gt;
&lt;/cfsavecontent&gt;
&lt;cfset contentFor(sidebar=categoriesSidebar)&gt;

&lt;!--- Include parent layout at `views/layout.cfm` ---&gt;
&lt;cfoutput&gt;
	##includeLayout(&quot;/layout.cfm&quot;)##
&lt;/cfoutput&gt;</pre>
