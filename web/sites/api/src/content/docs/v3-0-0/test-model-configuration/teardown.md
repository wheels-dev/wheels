---
title: teardown()
description: "Callback that executes after every test case when using Wheels’ legacy testing framework. It is typically used to clean up any data, variables, or state changes"
sidebar:
  label: teardown()
  order: 0
---

## Signature

`teardown()` — returns `any`

**Available in:** `test`
**Category:** Callback Functions

## Description

Callback that executes after every test case when using Wheels’ legacy testing framework. It is typically used to clean up any data, variables, or state changes made during a test, ensuring that each test runs in isolation and does not interfere with subsequent tests. This helps maintain reliability and consistency across the test suite.




## Examples

<pre><code class='javascript'>1. Basic cleanup after tests
function teardown() {
 // Remove temporary data created during the test
 queryExecute(&quot;DELETE FROM users WHERE email LIKE 'testuser%@example.com'&quot;);
}

2. Resetting application variables
function teardown() {
 // Clear session values to avoid leaking between tests
 structClear(session);
}

3. Rolling back test data with transactions
function teardown() {
 // Roll back the transaction started in setup
 transaction action=&quot;rollback&quot;;
}

4. Cleaning up mock objects or stubs
function teardown() {
 // Reset mock services after each test
 variables.mockService.reset();
}
</code></pre>
