---
title: startFormTag()
description: "Builds and returns a string containing the opening form tag. The form's action will be built according to the same rules as URLFor. Note: Pass any additional ar"
sidebar:
  label: startFormTag()
  order: 0
---

## Signature

`startFormTag()` — returns `any`




## Description

Builds and returns a string containing the opening form tag. The form's action will be built according to the same rules as URLFor. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `method` | `string` | yes | `post` | The type of method to use in the form tag. get and post are the options. |
| `multipart` | `boolean` | yes | `false` | Set to true if the form should be able to upload files. |
| `spamProtection` | `boolean` | yes | `false` | Set to true to protect the form against spammers (done with JavaScript). |
| `route` | `string` | yes | — | Name of a route that you have configured in config/routes.cfm. |
| `controller` | `string` | yes | — | Name of the controller to include in the URL. |
| `action` | `string` | yes | — | Name of the action to include in the URL. |
| `key` | `any` | yes | — | Key(s) to include in the URL. |
| `params` | `string` | yes | — | Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that CFWheels uses the & and = characters to split the parameters and encode them properly for you (using URLEncodedFormat() internally). However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1. |
| `anchor` | `string` | yes | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | yes | `true` | If true, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | yes | — | Set this to override the current host. |
| `protocol` | `string` | yes | — | Set this to override the current protocol. |
| `port` | `numeric` | yes | `0` | Set this to override the current port number. |
| `prepend` | `string` | yes | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | yes | — | String to append to the form control. Useful to wrap the form control with HTML tags. |

## Examples

<pre>&lt;!--- view code ---&gt;
&lt;cfoutput&gt;
    #startFormTag(action=&quot;create&quot;, spamProtection=true)#
        &lt;!--- your form controls ---&gt;
    #endFormTag()#
&lt;/cfoutput&gt;</pre>
