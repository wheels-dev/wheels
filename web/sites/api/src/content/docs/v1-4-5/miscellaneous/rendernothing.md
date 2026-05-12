---
title: renderNothing()
description: "Instructs the controller to render an empty string when it's finished processing the action. This is very similar to calling cfabort with the advantage that any"
sidebar:
  label: renderNothing()
  order: 0
---

## Signature

`renderNothing()` — returns `any`




## Description

Instructs the controller to render an empty string when it's finished processing the action. This is very similar to calling cfabort with the advantage that any after filters you have set on the action will still be run.


## Examples

<pre>// Render a blank white page to the client
renderNothing();</pre>
