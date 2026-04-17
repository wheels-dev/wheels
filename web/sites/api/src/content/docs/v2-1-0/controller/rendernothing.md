---
title: renderNothing()
description: "Instructs the controller to render an empty string when it's finished processing the action."
sidebar:
  label: renderNothing()
  order: 0
---

## Signature

`renderNothing()` — returns `void`

**Available in:** `controller`
**Category:** Rendering Functions

## Description

Instructs the controller to render an empty string when it's finished processing the action.
This is very similar to calling <code>cfabort</code> with the advantage that any after filters you have set on the action will still be run.




## Examples

<pre><code class='javascript'>// Render a blank white page to the client
renderNothing();</code></pre>
