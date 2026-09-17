---
title: can()
description: "Boolean policy check for conditionals and views (views run in the"
sidebar:
  label: can()
  order: 0
---

## Signature

`can()` — returns `boolean`

**Available in:** `controller`
**Category:** Authorization Functions

## Description

Boolean policy check for conditionals and views (views run in the
controller's <code>variables</code> scope, so <code>can()</code> is available in templates
automatically):
<code></code><code>
<cfif can("update", post)>##linkTo(text="Edit", route="editPost", key=post.id)##</cfif>
</code><code></code>
Returns <code>false</code> (deny) for a guest, for an empty record, and for a policy
method that does not return boolean <code>true</code>. A missing method throws
<code>Wheels.Policy.UnknownAction</code>. A missing policy class still throws
<code>Wheels.Policy.NotDefined</code> in development/testing so typos fail loud; in
production it returns <code>false</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `action` | `string` | yes | — | The policy method to check. |
| `record` | `any` | no | — | The model instance (or model class / model name string) to check against. Empty string denies. |

</div>

