---
title: clearCachableActions()
description: "Removes one or more actions from the list of cacheable actions in a controller. Use this when you want to prevent previously cached actions from being cached or"
sidebar:
  label: clearCachableActions()
  order: 0
---

## Signature

`clearCachableActions()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Removes one or more actions from the list of cacheable actions in a controller. Use this when you want to prevent previously cached actions from being cached or to reset caching for certain actions.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `action` | `string` | no | — | Action(s) to remove from cache. |

## Examples

<pre><code class='javascript'>1. Clear a single action from cache
clearCachableActions("termsOfUse");

2. Clear multiple actions from cache
clearCachableActions(actions="termsOfUse,codeOfConduct");

3. Clear all cacheable actions in the controller
clearCachableActions();</code></pre>
