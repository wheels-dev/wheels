---
title: packageTeardown()
description: "The packageTeardown() function is a callback in Wheels’ legacy testing framework. It runs once after the last test case in the test package. Use it to perform c"
sidebar:
  label: packageTeardown()
  order: 0
---

## Signature

`packageTeardown()` — returns `any`

**Available in:** `test`
**Category:** Callback Functions

## Description

The packageTeardown() function is a callback in Wheels’ legacy testing framework. It runs once after the last test case in the test package. Use it to perform cleanup tasks that are shared across all tests in the package, such as deleting test records, resetting application state, or clearing cached data.




## Examples

<pre><code class='javascript'>component extends=&quot;app.tests.Test&quot; {

    function packageSetup() {
        // Run once before any test in this package
        model(&quot;user&quot;).new(username=&quot;testuser&quot;, email=&quot;test@example.com&quot;).save();
    }

    function packageTeardown() {
        // Run once after all tests in this package

        // Delete test user
        var user = model(&quot;user&quot;).findOneByUsername(&quot;testuser&quot;);
        if (user) {
            user.delete();
        }

        // Clear test configuration
        structClear(application.testConfig);
    }

    function test_User_Exists() {
        var user = model(&quot;user&quot;).findOneByUsername(&quot;testuser&quot;);
        assert(&quot;user eq true&quot;);
    }
}
</code></pre>
