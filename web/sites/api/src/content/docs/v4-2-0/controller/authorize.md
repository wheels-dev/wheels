---
title: authorize()
description: "Authorizes the current user for an action on a record by dispatching to the"
sidebar:
  label: authorize()
  order: 0
---

## Signature

`authorize()` — returns `any`

**Available in:** `controller`
**Category:** Authorization Functions

## Description

Authorizes the current user for an action on a record by dispatching to the
record's policy (<code>app/policies/<ModelName>Policy.cfc</code>). Throws
<code>Wheels.NotAuthorized</code> (HTTP 403) when the policy denies, and returns the
record unchanged when it allows so the call can be inlined:
<code></code><code>
function update() {
post = authorize(model("Post").findByKey(params.key));
post.update(params.post);
}
</code><code></code>
A missing policy class throws <code>Wheels.Policy.NotDefined</code> in development and
testing (loud, Pundit-style, to catch typos) and silently denies in
production — the same environment posture as <code>tableName()</code> (##3079). A
policy class that lacks a method for the action throws
<code>Wheels.Policy.UnknownAction</code> (a typo, not a deny). Reserved <code>init</code> and
<code>scope</code> still deny as <code>Wheels.NotAuthorized</code>. Only boolean <code>true</code> grants.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `record` | `any` | yes | — | The model instance (or model class / model name string) to authorize against. |
| `action` | `string` | no | — | The policy method to dispatch. Defaults to the current `params.action`, resolved at call time. |

</div>

