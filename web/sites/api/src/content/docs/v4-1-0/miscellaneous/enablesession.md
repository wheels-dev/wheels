---
title: enableSession()
description: "One-line session-auth wiring for <code>config/services.cfm</code>."
sidebar:
  label: enableSession()
  order: 0
---

## Signature

`enableSession()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`


## Description

One-line session-auth wiring for <code>config/services.cfm</code>.
The auth subsystem ships complete (Authenticator strategy registry +
SessionStrategy with login/logout/currentUser and SID rotation) but
wiring it by hand spans two files: map the singletons here, then
register the strategy in <code>app/events/onapplicationstart.cfm</code>.
<code>enableSession()</code> collapses that into one idempotent call:
// config/services.cfm
enableSession(sessionKey = "wheels.auth");
The DI container is available in services.cfm (it is NOT available in
config/app.cfm — services.cfm is loaded after the container is built).
Manual wiring keeps working; this helper is the convenience path.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sessionKey` | `string` | no | `wheels.auth` |  |
| `onLogin` | `any` | no | — |  |
| `onLogout` | `any` | no | — |  |

</div>

