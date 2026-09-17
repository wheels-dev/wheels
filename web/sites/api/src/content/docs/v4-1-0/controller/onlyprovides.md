---
title: onlyProvides()
description: "Use this in an individual controller action to define which formats the action will respond with."
sidebar:
  label: onlyProvides()
  order: 0
---

## Signature

`onlyProvides()` — returns `void`

**Available in:** `controller`
**Category:** Provides Functions

## Description

Use this in an individual controller action to define which formats the action will respond with.
This can be used to define provides behavior in individual actions or to override a global setting set with <code>provides</code> in the controller's <code>config()</code>.
Restrictions are enforced (since 4.0.4): <code>renderWith()</code> falls back to the <code>html</code> view for a
format outside the list, and the automatic render in <code>$callAction()</code> skips view rendering for
non-acceptable, non-html formats.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `formats` | `string` | no | — | Formats to instruct the controller to provide. Valid values are `html` (the default), `xml`, `json`, `csv`, `pdf`, and `xls`. |
| `action` | `string` | no | `[runtime expression]` | Name of action, defaults to current. |

</div>

## Examples

<pre><code class='javascript'>// 1. Override a global `provides()` setting for a single action — only respond with HTML
onlyProvides(&quot;html&quot;);

// 2. Allow a specific action to respond with JSON and XML only
onlyProvides(&quot;json,xml&quot;);

// 3. Override the provides formats for a named action from within another context (e.g. config())
onlyProvides(formats=&quot;json&quot;, action=&quot;create&quot;);
</code></pre>
