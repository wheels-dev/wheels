---
title: getEmails()
description: "Primarily used in testing scenarios to retrieve information about the emails that were sent during the current request. It returns an array containing details o"
sidebar:
  label: getEmails()
  order: 0
---

## Signature

`getEmails()` — returns `array`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Primarily used in testing scenarios to retrieve information about the emails that were sent during the current request. It returns an array containing details of all sent emails, which allows you to verify the content, recipients, and other properties of the emails in your automated tests. This is especially useful for unit or functional tests where you want to assert that specific emails are being triggered by certain actions without actually sending them.




## Examples

<pre><code class='javascript'>1. Get all emails sent during the current request
emails = getEmails();

// Check if an email was sent to a specific recipient
for (var email in emails) {
    if (email.to EQ &quot;user@example.com&quot;) {
        writeOutput(&quot;Email sent to user@example.com&lt;br&gt;&quot;);
    }
}
</code></pre>
