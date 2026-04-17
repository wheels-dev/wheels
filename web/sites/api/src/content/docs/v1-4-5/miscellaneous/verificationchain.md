---
title: verificationChain()
description: "Returns an array of all the verifications set on this controller in the order in which they will be executed."
sidebar:
  label: verificationChain()
  order: 0
---

## Signature

`verificationChain()` — returns `any`




## Description

Returns an array of all the verifications set on this controller in the order in which they will be executed.


## Examples

<pre>// Get verification chain, remove the first item, and set it back
myVerificationChain = verificationChain();
ArrayDeleteAt(myVerificationChain, 1);
setVerificationChain(myVerificationChain);</pre>
