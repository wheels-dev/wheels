---
title: protectsFromForgery()
description: "Tells Wheels to protect <code>POST</code>ed requests from CSRF vulnerabilities."
sidebar:
  label: protectsFromForgery()
  order: 0
---

## Signature

`protectsFromForgery()` — returns `any`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Tells Wheels to protect <code>POST</code>ed requests from CSRF vulnerabilities.
Instructs the controller to verify that <code>params.authenticityToken</code> or <code>X-CSRF-Token</code> HTTP header is provided along with the request containing a valid authenticity token.
Call this method within a controller's <code>config</code> method, preferably the base <code>Controller.cfc</code> file, to protect the entire application.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `with` | `string` | no | `exception` | How to handle invalid authenticity token checks. Valid values are `exception` (the default — throws a `Wheels.InvalidAuthenticityToken` error), `abort` (aborts the request silently and sends a blank response to the client), and `ignore` (ignores the check and lets the request proceed). |
| `only` | `string` | no | — | List of actions that this check should only run on. Leave blank for all. |
| `except` | `string` | no | — | List of actions that this check should be omitted from running on. Leave blank for no exceptions. |

</div>

