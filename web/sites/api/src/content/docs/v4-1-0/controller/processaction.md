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
This is exposed in the API primarily for testing purposes; you would not usually call it directly unless in the test suite.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `includeFilters` | `string` | no | `true` | Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. This argument is generally inherited from the `processRequest` function during unit test execution. |

</div>

## Examples

<pre><code class='javascript'>// 1. Process the current action (runs before and after filters plus the action itself).
// Typically called automatically by the framework; used directly in unit tests.
result = controller.processAction();
// result -&gt; true

// 2. Process the action running only &quot;before&quot; filters (skip &quot;after&quot; filters).
result = controller.processAction(includeFilters=&quot;before&quot;);
// result -&gt; true

// 3. Process the action without running any filters.
result = controller.processAction(includeFilters=false);
// result -&gt; true
</code></pre>
