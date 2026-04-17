---
title: fail()
description: "Forces a test to fail intentionally. You can call fail() inside a test when you want to stop execution and explicitly mark the test as failed or highlight cases"
sidebar:
  label: fail()
  order: 0
---

## Signature

`fail()` — returns `void`

**Available in:** `test`


## Description

Forces a test to fail intentionally. You can call fail() inside a test when you want to stop execution and explicitly mark the test as failed or highlight cases that should never happen. When called, it throws an exception that results in a test failure. You can optionally pass a custom message to clarify why the failure occurred. Used in wheels legacy testing.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | no | — |  |

## Examples

<pre><code class='javascript'>1. Simple fail with no message
function test_should_fail_on_purpose() {
 fail();
};

Marks the test as failed without explanation.

2. Fail with a custom message
function test_should_fail_with_a_message() {
 fail(&quot;This path should never be reached!&quot;);
};

Produces a failure with the message This path should never be reached!.

3. Guarding unexpected conditions
function test_should_not_allow_null_users() {
 var user = getUserById(123);
 if (isNull(user)) {
     fail(&quot;Expected user with ID 123 to exist but got null.&quot;);
 }
};
</code></pre>
