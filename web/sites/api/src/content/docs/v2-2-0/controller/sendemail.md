---
title: sendEmail()
description: "Sends an email using a template and an optional layout to wrap it in."
sidebar:
  label: sendEmail()
  order: 0
---

## Signature

`sendEmail()` — returns `any`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Sends an email using a template and an optional layout to wrap it in.
Besides the CFWheels-specific arguments documented here, you can also pass in any argument that is accepted by the <code>cfmail</code> tag as well as your own arguments to be used by the view.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `template` | `string` | no | — | The path to the email template or two paths if you want to send a multipart email. if the `detectMultipart` argument is `false`, the template for the text version should be the first one in the list. This argument is also aliased as `templates`. |
| `from` | `string` | no | — | Email address to send from. |
| `to` | `string` | no | — | List of email addresses to send the email to. |
| `subject` | `string` | no | — | The subject line of the email. |
| `layout` | `any` | no | `false` | Layout(s) to wrap the email template in. This argument is also aliased as `layouts`. |
| `file` | `string` | no | — | A list of the names of the files to attach to the email. This will reference files stored in the `files` folder (or a path relative to it). This argument is also aliased as `files`. |
| `detectMultipart` | `boolean` | no | `true` | When set to `true` and multiple values are provided for the `template` argument, CFWheels will detect which of the templates is text and which one is HTML (by counting the `<` characters). |
| `deliver` | `boolean` | no | `true` | When set to `false`, the email will not be sent. |
| `writeToFile` | `string` | no | — | The file to which the email contents will be written |

## Examples

<pre><code class='javascript'>// Get a member and send a welcome email, passing in a few custom variables to the template
newMember = model(&quot;member&quot;).findByKey(params.member.id);
sendEmail(
	to=newMember.email,
	template=&quot;myemailtemplate&quot;,
	subject=&quot;Thank You for Becoming a Member&quot;,
	recipientName=newMember.name,
	startDate=newMember.startDate
);</code></pre>
