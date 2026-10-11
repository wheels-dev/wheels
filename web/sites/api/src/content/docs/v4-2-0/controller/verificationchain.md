---
title: verificationChain()
description: "Returns an array of all the verifications set on this controller in the order in which they will be executed."
sidebar:
  label: verificationChain()
  order: 0
---

## Signature

`verificationChain()` — returns `array`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Returns an array of all the verifications set on this controller in the order in which they will be executed.




## Examples

<pre><code class='javascript'>// 1. Get verification chain, remove the first item, and set it back.
myVerificationChain = verificationChain();
arrayDeleteAt(myVerificationChain, 1);
setVerificationChain(myVerificationChain);

// 2. Inspect the number of verifications registered on this controller.
chain = verificationChain();
writeOutput(&quot;Verifications registered: &quot; &amp; arrayLen(chain));

// 3. Loop over the chain to find verifications that apply to a specific action.
chain = verificationChain();
for (item in chain) {
	if (listFindNoCase(item.only, &quot;create&quot;)) {
		writeOutput(&quot;Verification applies to create: &quot; &amp; serializeJSON(item));
	}
}
</code></pre>
