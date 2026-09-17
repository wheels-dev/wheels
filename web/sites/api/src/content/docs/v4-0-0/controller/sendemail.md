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
Besides the Wheels-specific arguments documented here, you can also pass in any argument that is accepted by the <code>cfmail</code> tag as well as your own arguments to be used by the view.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `template` | `string` | no | — | The path to the email template or two paths if you want to send a multipart email. if the `detectMultipart` argument is `false`, the template for the text version should be the first one in the list. This argument is also aliased as `templates`. |
| `from` | `string` | yes | — | Email address to send from. |
| `to` | `string` | yes | — | List of email addresses to send the email to. |
| `subject` | `string` | yes | — | The subject line of the email. |
| `layout` | `any` | no | `false` | Layout(s) to wrap the email template in. This argument is also aliased as `layouts`. |
| `file` | `string` | no | — | A list of the names of the files to attach to the email. This will reference files stored in the `files` folder (or a path relative to it). This argument is also aliased as `files`. |
| `detectMultipart` | `boolean` | no | `true` | When set to `true` and multiple values are provided for the `template` argument, Wheels will detect which of the templates is text and which one is HTML (by counting the `<` characters). |
| `deliver` | `boolean` | no | `true` | When set to `false`, the email will not be sent. |
| `writeToFile` | `string` | no | — | Path that receives the rendered text and/or HTML body. This is a debug dump of the body content, not a MIME `.eml` — no `From`/`To`/`Subject`/`Content-Type` headers are written. A `.eml` extension will not open as a rendered message in Outlook; use `.html`/`.txt` and open the file in a browser or editor. |

</div>

## Examples

<pre><code class='javascript'>1. Basic email to a new user
newMember = model(&quot;member&quot;).findByKey(params.member.id);

sendEmail(
    to=newMember.email,
    template=&quot;welcomeEmail&quot;,
    subject=&quot;Thank You for Joining!&quot;,
    recipientName=newMember.name,
    startDate=newMember.startDate
);

2. Multipart email (HTML + text)
sendEmail(
    to=&quot;user@example.com&quot;,
    template=&quot;welcomeEmailText, welcomeEmailHTML&quot;,
    subject=&quot;Welcome!&quot;,
    detectMultipart=true
);

3. Write the rendered body to a file without sending
// writeToFile dumps the text/HTML body only — it is not a MIME .eml.
// Open the file in a text editor (or a browser for HTML). A .eml
// extension will show raw HTML tags in Outlook.
sendEmail(
    to=&quot;user@example.com&quot;,
    template=&quot;testEmail&quot;,
    subject=&quot;Testing Email&quot;,
    writeToFile=&quot;#expandPath('./tmp/testEmail.html')#&quot;,
    deliver=false
);</code></pre>

