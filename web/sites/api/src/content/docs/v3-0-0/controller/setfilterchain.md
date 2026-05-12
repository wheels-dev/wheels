---
title: setFilterChain()
description: "Provides a low-level way to define the complete filter chain for a controller. This lets you explicitly specify the sequence of filters, their scope, and the ac"
sidebar:
  label: setFilterChain()
  order: 0
---

## Signature

`setFilterChain()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Provides a low-level way to define the complete filter chain for a controller. This lets you explicitly specify the sequence of filters, their scope, and the actions they apply to, all in a single configuration. Filters are functions that run before, after, or around actions to handle tasks such as authentication, logging, or IP restrictions.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `chain` | `array` | yes | — | An array of structs, each of which represent an `argumentCollection` that get passed to the `filters` function. This should represent the entire filter chain that you want to use for this controller. |

</div>

## Examples

<pre><code class='javascript'>1. Basic filter chain
// Set filter chain directly
setFilterChain([
    {through=&quot;restrictAccess&quot;}, // runs for all actions by default
    {through=&quot;isLoggedIn, checkIPAddress&quot;, except=&quot;home, login&quot;}, // exclude certain actions
    {type=&quot;after&quot;, through=&quot;logConversion&quot;, only=&quot;thankYou&quot;} // after filter for specific action
]);

//First filter: restrictAccess runs before all actions.
//Second filter: isLoggedIn and checkIPAddress run before all actions except home and login.
//Third filter: logConversion runs after the thankYou action only.

2. Using only and except with different filter types
setFilterChain([
    {through=&quot;authenticateUser&quot;, only=&quot;edit, update, delete&quot;}, // only for sensitive actions
    {through=&quot;trackActivity&quot;, except=&quot;index, show&quot;},           // for most actions except viewing
    {type=&quot;after&quot;, through=&quot;sendAnalytics&quot;}                   // after all actions
]);

//Demonstrates selective filtering with only and except.
//Can combine before (default) and after filters in the same chain.

3. Multiple filters in one chain struct
setFilterChain([
    {through=&quot;validateSession, checkPermissions&quot;, only=&quot;admin, settings&quot;},
    {through=&quot;logRequest&quot;},
    {type=&quot;after&quot;, through=&quot;cleanupTempFiles&quot;}
]);

//Multiple filters can run together (validateSession and checkPermissions).
//Mix of before and after filters ensures proper order and execution context.</code></pre>
