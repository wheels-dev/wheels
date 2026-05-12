---
title: setVerificationChain()
description: "Allows you to define the entire verification chain for a controller in a low-level, structured way. Verification chains are used to validate requests, ensuring"
sidebar:
  label: setVerificationChain()
  order: 0
---

## Signature

`setVerificationChain()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Allows you to define the entire verification chain for a controller in a low-level, structured way. Verification chains are used to validate requests, ensuring they meet specific requirements (like HTTP method, parameters, or types) before the controller action executes. Instead of defining individual <code>verifies()</code> calls in each action, you can use <code>setVerificationChain()</code> to set all verifications at once.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `chain` | `array` | yes | — | An array of structs, each of which represent an `argumentCollection` that get passed to the `verifies` function. This should represent the entire verification chain that you want to use for this controller. |

</div>

## Examples

<pre><code class='javascript'>1. Basic verification chain
component extends=&quot;Controller&quot; {

    function init() {
        // Set verification rules for multiple actions
        setVerificationChain([
            {only=&quot;handleForm&quot;, post=true},
            {only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;}
        ]);
    }

    function handleForm() {
        // Action logic here
    }

    function edit() {
        // Action logic here
    }
}

2. Adding custom error handling
component extends=&quot;Controller&quot; {

    function init() {
        setVerificationChain([
            {only=&quot;edit&quot;, get=true, params=&quot;userId&quot;, paramsTypes=&quot;integer&quot;, handler=&quot;index&quot;, error=&quot;Invalid userId&quot;},
            {only=&quot;delete&quot;, post=true, params=&quot;id&quot;, paramsTypes=&quot;integer&quot;, error=&quot;Missing or invalid id&quot;}
        ]);
    }

    function edit() {
        /* edit logic */ 
    }
    function delete() {
        /* delete logic */ 
    }
}</code></pre>
