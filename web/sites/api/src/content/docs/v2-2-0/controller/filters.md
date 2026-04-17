---
title: filters()
description: "Tells CFWheels to run a function before an action is run or after an action has been run."
sidebar:
  label: filters()
  order: 0
---

## Signature

`filters()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Tells CFWheels to run a function before an action is run or after an action has been run.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `through` | `string` | yes | — | Function(s) to execute before or after the action(s). |
| `type` | `string` | no | `before` | Whether to run the function(s) before or after the action(s). |
| `only` | `string` | no | — | Pass in a list of action names (or one action name) to tell CFWheels that the filter function(s) should only be run on these actions. |
| `except` | `string` | no | — | Pass in a list of action names (or one action name) to tell CFWheels that the filter function(s) should be run on all actions except the specified ones. |
| `placement` | `string` | no | `append` | Pass in `prepend` to prepend the function(s) to the filter chain instead of appending. |

## Examples

<pre><code class='javascript'>// Always execute `restrictAccess` before all actions in this controller.
filters(&quot;restrictAccess&quot;);

// Always execute `isLoggedIn` and `checkIPAddress` (in that order) before all actions in this controller, except the `home` and `login` actions.
filters(through=&quot;isLoggedIn, checkIPAddress&quot;, except=&quot;home, login&quot;);
</code></pre>
