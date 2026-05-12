---
title: processAction()
description: "Process the specified action of the controller."
sidebar:
  label: processAction()
  order: 0
---

## Signature

`processAction()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Process the specified action of the controller.
This is exposed in the API primarily for testing purposes; you would not usually call it directly unless in the test suite. The optional includeFilters argument allows you to control whether before filters, after filters, or no filters at all should run when invoking the action. By default, all filters execute unless explicitly restricted.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `includeFilters` | `string` | no | `true` | Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. This argument is generally inherited from the `processRequest` function during unit test execution. |

</div>

## Examples

<pre><code class='javascript'>1. Run an action with default behavior (all filters applied)
result = processAction(&quot;show&quot;);
// Executes the &quot;show&quot; action of the current controller with before/after filters

2. Run an action but only apply &quot;before&quot; filters
result = processAction(&quot;edit&quot;, includeFilters=&quot;before&quot;);
// Useful for testing preconditions without running the full action

3. Run an action but only apply &quot;after&quot; filters
result = processAction(&quot;update&quot;, includeFilters=&quot;after&quot;);
// Useful for testing cleanup logic that runs post-action

4. Run an action without any filters
result = processAction(&quot;delete&quot;, includeFilters=false);
// Skips before/after filters, only executes the &quot;delete&quot; action

5. Simulating in a test case
it(&quot;should process the show action without filters&quot;, function() {
    var controller = controller(&quot;users&quot;);
    var success = controller.processAction(&quot;show&quot;, includeFilters=false);
    expect(success).toBeTrue();
});
</code></pre>
