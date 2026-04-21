---
title: filters()
description: "The filters() function lets you specify methods in your controller that should run automatically either before or after certain actions. Filters are useful for"
sidebar:
  label: filters()
  order: 0
---

## Signature

`filters()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

The filters() function lets you specify methods in your controller that should run automatically either before or after certain actions. Filters are useful for handling cross-cutting concerns such as authentication, authorization, logging, or cleanup, without having to repeat the same code inside each action. By default, filters run before the action, but you can configure them to run after, limit them to specific actions, exclude them from others, or control their placement in the filter chain.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `through` | `string` | yes | — | Function(s) to execute before or after the action(s). |
| `type` | `string` | no | `before` | Whether to run the function(s) before or after the action(s). |
| `only` | `string` | no | — | Pass in a list of action names (or one action name) to tell Wheels that the filter function(s) should only be run on these actions. |
| `except` | `string` | no | — | Pass in a list of action names (or one action name) to tell Wheels that the filter function(s) should be run on all actions except the specified ones. |
| `placement` | `string` | no | `append` | Pass in `prepend` to prepend the function(s) to the filter chain instead of appending. |

</div>

## Examples

<pre><code class='javascript'>1. Run a filter before all actions
// Always execute restrictAccess before every action
filters(&quot;restrictAccess&quot;);

2. Multiple filters before all actions
// Run both isLoggedIn and checkIPAddress before all actions
filters(through=&quot;isLoggedIn, checkIPAddress&quot;);

3. Exclude specific actions
// Run filters before all actions, except home and login
filters(through=&quot;isLoggedIn, checkIPAddress&quot;, except=&quot;home, login&quot;);

4. Limit filters to specific actions
// Only run ensureAdmin before the delete action
filters(through=&quot;ensureAdmin&quot;, only=&quot;delete&quot;);

5. Run filters after an action
// Run logAction after every action
filters(through=&quot;logAction&quot;, type=&quot;after&quot;);
</code></pre>
