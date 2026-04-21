---
title: caches()
description: "Tells CFWheels to cache one or more actions."
sidebar:
  label: caches()
  order: 0
---

## Signature

`caches()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Tells CFWheels to cache one or more actions.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `action` | `string` | no | — | Action(s) to cache. This argument is also aliased as `actions`. |
| `time` | `numeric` | no | `60` | Minutes to cache the action(s) for. |
| `static` | `boolean` | no | `false` | Set to `true` to tell CFWheels that this is a static page and that it can skip running the controller filters (before and after filters set on actions). Please note that the `onSessionStart` and `onRequestStart` events still execute though. |
| `appendToKey` | `string` | no | — | List of variables to be evaluated at runtime and included in the cache key so that content can be cached separately. |

</div>

## Examples

<pre><code class='javascript'>// Cache the `termsOfUse` action.
caches(&quot;termsOfUse&quot;);

// Cache the `termsOfUse` action for 30 minutes.
caches(actions=&quot;browseByUser, browseByTitle&quot;, time=30);

// Cache the `termsOfUse` and `codeOfConduct` actions, including their filters.
caches(actions=&quot;termsOfUse, codeOfConduct&quot;, static=true);

// Cache content separately based on region.
caches(action=&quot;home&quot;, key=&quot;request.region&quot;);
</code></pre>
