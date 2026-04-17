---
title: setup()
description: "Callback used in Wheels legacy testing framework. It runs before every individual test case within a test suite. This allows you to prepare the test environment"
sidebar:
  label: setup()
  order: 0
---

## Signature

`setup()` — returns `any`

**Available in:** `test`
**Category:** Callback Functions

## Description

Callback used in Wheels legacy testing framework. It runs before every individual test case within a test suite. This allows you to prepare the test environment, initialize objects, or reset state before each test executes.




## Examples

<pre><code class='javascript'>1. Basic setup for a test suite
component extends=&quot;app.tests.Test&quot; {

    function setup() {
        // Initialize a new user object before each test
        variables.user = model(&quot;user&quot;).new();
    }

    function test_User_Creation() {
        variables.user.firstName = &quot;John&quot;;
        variables.user.lastName = &quot;Doe&quot;;

        assert(&quot;variables.user.save() eq true&quot;);
    }

    function test_User_Email_Validation() {
        variables.user.email = &quot;invalid-email&quot;;

        assert(&quot;variables.user.valid() eq false&quot;);
    }
}

2. Reset database table before each test
component extends=&quot;app.tests.Test&quot; {

    function setup() {
        // Delete all records in the users table before each test
        model(&quot;user&quot;).deleteAll();
    }

    function test_User_Insert() {
        newUser = model(&quot;user&quot;).new(firstName=&quot;Alice&quot;, lastName=&quot;Smith&quot;);
        assert(&quot;newUser.save() eq true&quot;);
    }

    function test_User_Count() {
        count = model(&quot;user&quot;).count();
        assert(&quot;count eq 0&quot;);
    }
}</code></pre>
