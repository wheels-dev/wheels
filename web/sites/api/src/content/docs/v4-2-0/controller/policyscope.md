---
title: policyScope()
description: "Narrows a collection to the records the current user may see by delegating"
sidebar:
  label: policyScope()
  order: 0
---

## Signature

`policyScope()` — returns `any`

**Available in:** `controller`
**Category:** Authorization Functions

## Description

Narrows a collection to the records the current user may see by delegating
to the policy's <code>scope()</code> method. Returns whatever the policy returns —
conventionally a chainable finder you keep composing:
<code></code><code>
function index() {
posts = policyScope(model("Post")).findAll(page = params.page, perPage = 25);
}
</code><code></code>
Pass the model class first and chain scopes after the call
(<code>policyScope(model("Post")).active()</code>) — a query-builder or scope chain
that is already in flight cannot be introspected for its model. When the
policy class is missing, this throws <code>Wheels.Policy.NotDefined</code> in
development/testing and returns a default-deny (no rows) chain in
production.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `collection` | `any` | yes | — | The model class to narrow. |

</div>

