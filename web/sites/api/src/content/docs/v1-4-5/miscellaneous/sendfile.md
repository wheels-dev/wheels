---
title: sendFile()
description: "Sends a file to the user (from the files folder or a path relative to it by default)."
sidebar:
  label: sendFile()
  order: 0
---

## Signature

`sendFile()` — returns `any`




## Description

Sends a file to the user (from the files folder or a path relative to it by default).

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `file` | `string` | yes | — | The file to send to the user. |
| `name` | `string` | yes | — | The file name to show in the browser download dialog box. |
| `type` | `string` | yes | — | The HTTP content type to deliver the file as. |
| `disposition` | `string` | yes | `attachment` | Set to inline to have the browser handle the opening of the file (possibly inline in the browser) or set to attachment to force a download dialog box. |
| `directory` | `string` | yes | — | Directory outside of the webroot where the file exists. Must be a full path. |
| `deleteFile` | `boolean` | yes | `false` | Pass in true to delete the file on the server after sending it. |

## Examples

<pre>// Send a PDF file to the user
sendFile(file=&quot;wheels_tutorial_20081028_J657D6HX.pdf&quot;);

// Send the same file but give the user a different name in the browser dialog window
sendFile(file=&quot;wheels_tutorial_20081028_J657D6HX.pdf&quot;, name=&quot;Tutorial.pdf&quot;);

// Send a file that is located outside of the web root
sendFile(file=&quot;../../tutorials/wheels_tutorial_20081028_J657D6HX.pdf&quot;);</pre>
