---
title: clearCachableActions()
description: "Clears cached action metadata for current controller."
sidebar:
  label: clearCachableActions()
  order: 0
---

## Signature

`clearCachableActions()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Clears cached action metadata for current controller.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `action` | `string` | no | — | Optional. A single action or list of actions to clear. If not provided, clears all cached actions of current controller. |

</div>

## Examples

<pre><code class='javascript'>// 1. Clear all cached action metadata for the current controller.
clearCachableActions();

// 2. Clear the cached metadata for a single action.
clearCachableActions(action=&quot;termsOfUse&quot;);

// 3. Clear the cached metadata for a list of specific actions.
clearCachableActions(action=&quot;browseByUser,browseByTitle&quot;);
</code></pre>
