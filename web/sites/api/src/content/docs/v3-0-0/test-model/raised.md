---
title: raised()
description: "Used in legacy Wheels testing to catch errors or exceptions raised by a given CFML expression. It evaluates the expression and, if an error occurs, returns the"
sidebar:
  label: raised()
  order: 0
---

## Signature

`raised()` — returns `string`

**Available in:** `test`
**Category:** Testing Functions

## Description

Used in legacy Wheels testing to catch errors or exceptions raised by a given CFML expression. It evaluates the expression and, if an error occurs, returns the type of the error. This is especially useful when writing tests to ensure that specific operations correctly trigger exceptions under invalid or unexpected conditions. By using raised(), you can assert that your code behaves safely and predictably when encountering errors.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `expression` | `string` | yes | — | String containing CFML expression to evaluate |

## Examples

<pre><code class='javascript'>1. Testing for a specific exception
// Assume updateUser() should throw an error if email is invalid
errorType = raised('model(&quot;user&quot;).updateUser({email=&quot;invalid-email&quot;})');
assert(&quot;errorType eq Wheels.InvalidEmailException&quot;);

2. Using raised() in a test case
function testInvalidPassword() {
    var errorType = raised('model(&quot;user&quot;).login(username=&quot;jdoe&quot;, password=&quot;wrong&quot;)');
    writeOutput(&quot;Caught error type: &quot; & errorType);
    // Output: Caught error type: Wheels.InvalidPassword
}

3. Catching any error
var errorType = raised('1 / 0'); // Division by zero
writeOutput(errorType);
</code></pre>
