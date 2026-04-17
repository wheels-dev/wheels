---
title: verificationChain()
description: "Returns an array of all verifications (filters, before-actions, or checks) that are configured for the current controller, in the order they will be executed. T"
sidebar:
  label: verificationChain()
  order: 0
---

## Signature

`verificationChain()` — returns `array`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Returns an array of all verifications (filters, before-actions, or checks) that are configured for the current controller, in the order they will be executed. This allows you to inspect, modify, or reorder the verifications dynamically.




## Examples

<pre><code class='javascript'>1. Get verification chain, remove the first item, and set it back.
myVerificationChain = verificationChain();
ArrayDeleteAt(myVerificationChain, 1);
setVerificationChain(myVerificationChain);
</code></pre>
