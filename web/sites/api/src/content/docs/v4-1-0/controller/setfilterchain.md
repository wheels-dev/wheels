---
title: setFilterChain()
description: "Use this function if you need a more low level way of setting the entire filter chain for a controller."
sidebar:
  label: setFilterChain()
  order: 0
---

## Signature

`setFilterChain()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Use this function if you need a more low level way of setting the entire filter chain for a controller.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `chain` | `array` | yes | — | An array of structs, each of which represent an `argumentCollection` that get passed to the `filters` function. This should represent the entire filter chain that you want to use for this controller. |

</div>

## Examples

<pre><code class='javascript'>// 1. Set the entire filter chain directly using an array of structs
setFilterChain([
	{through=&quot;restrictAccess&quot;},
	{through=&quot;isLoggedIn, checkIPAddress&quot;, except=&quot;home, login&quot;},
	{type=&quot;after&quot;, through=&quot;logConversion&quot;, only=&quot;thankYou&quot;}
]);

// 2. Replace an inherited filter chain in a child controller by starting fresh
// In app/controllers/Admin.cfc config():
parentChain = filterChain();
// Modify parentChain as needed, then reassign it wholesale
setFilterChain([
	{through=&quot;requireAdmin&quot;},
	{through=&quot;loadCurrentUser&quot;, except=&quot;login&quot;},
	{type=&quot;after&quot;, through=&quot;auditAction&quot;}
]);

// 3. Conditionally swap the filter chain based on application mode
if (get(&quot;environment&quot;) == &quot;testing&quot;) {
	setFilterChain([
		{through=&quot;stubAuthentication&quot;}
	]);
} else {
	setFilterChain([
		{through=&quot;requireSSL&quot;},
		{through=&quot;authenticate&quot;},
		{type=&quot;after&quot;, through=&quot;trackPageView&quot;}
	]);
}
</code></pre>
