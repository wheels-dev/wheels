---
title: caches()
description: "Tells Wheels to cache one or more actions."
sidebar:
  label: caches()
  order: 0
---

## Signature

`caches()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Tells Wheels to cache one or more actions.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `action` | `string` | no | — | Action(s) to cache. This argument is also aliased as `actions`. |
| `time` | `numeric` | no | `60` | Minutes to cache the action(s) for. |
| `static` | `boolean` | no | `false` | Set to `true` to tell Wheels that this is a static page and that it can skip running the controller filters (before and after filters set on actions). Please note that the `onSessionStart` and `onRequestStart` events still execute though. |
| `appendToKey` | `string` | no | — | List of variables to be evaluated at runtime and included in the cache key so that content can be cached separately. |

</div>

## Examples

<pre><code class='javascript'>// 1. Cache the `termsOfUse` action for the default 60 minutes.
caches(&quot;termsOfUse&quot;);

// 2. Cache two actions for 30 minutes.
caches(actions=&quot;browseByUser,browseByTitle&quot;, time=30);

// 3. Cache the `termsOfUse` and `codeOfConduct` actions, including their filters.
caches(actions=&quot;termsOfUse,codeOfConduct&quot;, static=true);

// 4. Cache content separately based on region.
caches(action=&quot;home&quot;, appendToKey=&quot;request.region&quot;);
</code></pre>
