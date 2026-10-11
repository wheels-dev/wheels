---
title: initSSEStream()
description: "Initialize a streaming SSE connection that bypasses the normal Wheels rendering pipeline."
sidebar:
  label: initSSEStream()
  order: 0
---

## Signature

`initSSEStream()` — returns `any`

**Available in:** `controller`


## Description

Initialize a streaming SSE connection that bypasses the normal Wheels rendering pipeline.
Returns a writer object that can be used with sendSSEEvent() and closeSSEStream().
This enables sending multiple events over a single connection.
Note: This bypasses layouts and after-filters. Use for true streaming endpoints only.


