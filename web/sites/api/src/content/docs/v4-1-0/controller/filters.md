---
title: filters()
description: "Tells Wheels to run a function before an action is run or after an action has been run."
sidebar:
  label: filters()
  order: 0
---

## Signature

`filters()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Tells Wheels to run a function before an action is run or after an action has been run.



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

<pre><code class='javascript'>// 1. Run `restrictAccess` before every action in this controller (declared inside config()).
filters(&quot;restrictAccess&quot;);

// 2. Run two before-filters on every action except `home` and `login`.
filters(through=&quot;isLoggedIn, checkIPAddress&quot;, except=&quot;home, login&quot;);

// 3. Run `auditLog` after only the `create`, `update`, and `delete` actions.
filters(through=&quot;auditLog&quot;, type=&quot;after&quot;, only=&quot;create, update, delete&quot;);

// 4. Prepend a filter so it runs before any already-registered filters.
filters(through=&quot;maintenanceCheck&quot;, placement=&quot;prepend&quot;);

// Note: filter functions must be declared as `private` in the controller
// to prevent them from being routed as public actions.
// Example controller setup:
// component extends=&quot;Controller&quot; {
//     function config() {
//         filters(&quot;restrictAccess&quot;);
//     }
//     private function restrictAccess() {
//         if (!isLoggedIn()) {
//             redirectTo(route=&quot;login&quot;);
//         }
//     }
// }
</code></pre>
