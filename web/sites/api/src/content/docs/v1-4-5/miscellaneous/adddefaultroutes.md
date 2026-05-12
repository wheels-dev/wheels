---
title: addDefaultRoutes()
description: "Adds the default CFWheels routes (for example, [controller]/[action]/[key], etc.) to your application. Only use this method if you have set loadDefaultRoutes to"
sidebar:
  label: addDefaultRoutes()
  order: 0
---

## Signature

`addDefaultRoutes()` — returns `any`




## Description

Adds the default CFWheels routes (for example, [controller]/[action]/[key], etc.) to your application. Only use this method if you have set loadDefaultRoutes to false and want to control exactly where in the route order you want to place the default routes.


## Examples

<pre>&lt;!--- Adds the default routes to your application (done in `config/routes.cfm`) ---&gt;
&lt;cfset addDefaultRoutes()&gt;</pre>
