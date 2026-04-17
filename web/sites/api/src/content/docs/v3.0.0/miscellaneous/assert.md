---
title: assert()
description: "Asserts that an expression evaluates to true in a test. If the expression evaluates to false, the test will fail and an error will be raised. This is one of the"
sidebar:
  label: assert()
  order: 0
---

## Signature

`assert()` — returns `void`

**Available in:** `test`


## Description

Asserts that an expression evaluates to true in a test. If the expression evaluates to false, the test will fail and an error will be raised. This is one of the core testing functions available when writing legacy tests in Wheels.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `expression` | `string` | yes | — |  |

## Examples

<pre><code class='javascript'>1. Basic true assertion
// Passes because 2 + 2 = 4
assert("2 + 2 EQ 4");

2. Assertion that fails
// This will fail the test because 5 is not less than 3
assert("5 LT 3");

3. With model object conditions
user = model("user").findByKey(1);

// Assert that the user has an email set
assert(len(user.email));</code></pre>
