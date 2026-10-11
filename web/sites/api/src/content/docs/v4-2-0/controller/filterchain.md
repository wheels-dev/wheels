---
title: filterChain()
description: "Returns an array of all the filters set on current controller in the order in which they will be executed."
sidebar:
  label: filterChain()
  order: 0
---

## Signature

`filterChain()` — returns `array`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Returns an array of all the filters set on current controller in the order in which they will be executed.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `type` | `string` | no | `all` | Use this argument to return only before or after filters. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the entire filter chain for the current controller
myFilterChain = filterChain();
// myFilterChain -&gt; array of structs, each with keys: through, type, only, except, arguments
// e.g. [{ through: &quot;checkLogin&quot;, type: &quot;before&quot;, only: &quot;&quot;, except: &quot;&quot; }, ...]

// 2. Get only the before-filters
beforeFilters = filterChain(type=&quot;before&quot;);
for (f in beforeFilters) {
    writeOutput(f.through);
}

// 3. Get only the after-filters
afterFilters = filterChain(type=&quot;after&quot;);
writeOutput(arrayLen(afterFilters));
</code></pre>
