---
title: packageSetup()
description: "The packageSetup() function is a callback in Wheels’ legacy testing framework. It runs once before the first test case in the test package. Use it to perform se"
sidebar:
  label: packageSetup()
  order: 0
---

## Signature

`packageSetup()` — returns `any`

**Available in:** `test`
**Category:** Callback Functions

## Description

The packageSetup() function is a callback in Wheels’ legacy testing framework. It runs once before the first test case in the test package. Use it to perform setup tasks that are shared across all tests in the package, such as initializing data, creating test records, or configuring environment settings.




## Examples

<pre><code class='javascript'>component extends=&quot;app.tests.Test&quot; {

    function packageSetup() {
        // Run once before any test in this package
        
        // Create a test user
        model(&quot;user&quot;).new(username=&quot;testuser&quot;, email=&quot;test@example.com&quot;).save();

        // Initialize test data
        application.testConfig = {
            siteName: &quot;Wheels Test&quot;
        };
    }

    function test_User_Creation() {
        var user = model(&quot;user&quot;).findOneByUsername(&quot;testuser&quot;);
        assert(&quot;user eq true&quot;);
    }

    function test_Config_Value() {
        assert(&quot;application.testConfig.siteName eq 'Wheels Test'&quot;);
    }
}
</code></pre>
