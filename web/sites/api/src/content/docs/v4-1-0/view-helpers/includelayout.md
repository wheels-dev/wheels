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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `layout` | Name of the layout file to include. |

</div>

## Examples

<pre><code class='javascript'>// 1. Include the default parent layout from within a child layout
// (looks for `app/views/layout.cfm` by default)
#includeLayout()#

// 2. Include a specific parent layout by path
// (looks for `app/views/layouts/application.cfm`)
#includeLayout(&quot;/layouts/application.cfm&quot;)#

// 3. Pass section content to the parent layout before including it
// Capture sidebar markup to make it available in the parent layout
&lt;cfsavecontent variable=&quot;sidebar&quot;&gt;
  &lt;nav&gt;
    #includePartial(&quot;categories&quot;)#
  &lt;/nav&gt;
&lt;/cfsavecontent&gt;
&lt;cfset contentFor(sidebar=sidebar)&gt;

// Then pull in the parent layout that renders the sidebar via includeContent()
#includeLayout(&quot;/layouts/application.cfm&quot;)#
</code></pre>
