---
title: debug()
description: "Used in tests to inspect any expression. It behaves like a cfdump but is tailored for the testing environment. This helps you examine values while writing or ru"
sidebar:
  label: debug()
  order: 0
---

## Signature

`debug()` — returns `any`

**Available in:** `test`
**Category:** Testing Functions

## Description

Used in tests to inspect any expression. It behaves like a cfdump but is tailored for the testing environment. This helps you examine values while writing or running legacy tests.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `expression` | `string` | yes | — | The expression to examine |
| `display` | `boolean` | no | `true` | Whether to display the debug call. False returns without outputting anything into the buffer. Good when you want to leave the debug command in the test for later purposes, but don't want it to display |

</div>

## Examples

<pre><code class='javascript'>Example 1: Basic usage
// In a test
user = model("user").findByKey(1);

// Inspect the user object
debug(user);

Dumps the contents of the user object to the test output.

---

Example 2: Debug without output
// Evaluate an expression but don't output
result = someFunction();
debug(result, display=false);

Useful when you want to leave the debug call in place for later but don’t want it to show in test output immediately.

---

Example 3: Debug an expression directly
debug("2 + 2");

Quickly examines a simple expression, like a calculation or string.</code></pre>
