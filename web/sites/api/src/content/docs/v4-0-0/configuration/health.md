---
title: health()
description: "Register a health check route at <code>/health</code> (or a custom path). Returns a JSON response with status and timestamp by default, or delegates to a custom"
sidebar:
  label: health()
  order: 0
---

## Signature

`health()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Register a health check route at <code>/health</code> (or a custom path). Returns a JSON response with status and timestamp by default, or delegates to a custom controller action.
This is useful for container orchestration (Kubernetes liveness/readiness probes), load balancer health checks, and monitoring tools.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `to` | `string` | no | `wheels#health` | Set `controller##action` combination for a custom health check handler. If not provided, a default handler returns `{"status":"ok","timestamp":"..."}`. |
| `path` | `string` | no | `health` | Override the URL path. Defaults to `"health"`. |
| `name` | `string` | no | `health` | Override the route name. Defaults to `"health"`. |

</div>

