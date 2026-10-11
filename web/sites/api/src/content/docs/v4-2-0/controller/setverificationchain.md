---
title: setVerificationChain()
description: "Use this function if you need a more low level way of setting the entire verification chain for a controller."
sidebar:
  label: setVerificationChain()
  order: 0
---

## Signature

`setVerificationChain()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Use this function if you need a more low level way of setting the entire verification chain for a controller.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `chain` | `array` | yes | — | An array of structs, each of which represent an `argumentCollection` that get passed to the `verifies` function. This should represent the entire verification chain that you want to use for this controller. |

</div>

## Examples

<pre><code class='javascript'>// 1. Set the entire verification chain directly using an array of structs
setVerificationChain([
	{only=&quot;handleForm&quot;, post=true},
	{only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;},
	{only=&quot;delete&quot;, post=true, session=&quot;currentUser&quot;, handler=&quot;accessDenied&quot;}
]);

// 2. Get the existing chain, modify it, and set it back
chain = verificationChain();
ArrayAppend(chain, {only=&quot;create,update&quot;, post=true});
setVerificationChain(chain);

// 3. Replace the chain built by a parent controller with a stricter one
setVerificationChain([
	{except=&quot;index,show&quot;, post=true, session=&quot;isAdmin&quot;, handler=&quot;requireAdmin&quot;},
	{only=&quot;destroy&quot;, post=true}
]);
</code></pre>
