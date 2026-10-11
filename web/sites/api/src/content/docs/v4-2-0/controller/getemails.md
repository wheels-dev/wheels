---
title: getEmails()
description: "Primarily used for testing to get information about emails sent during the request."
sidebar:
  label: getEmails()
  order: 0
---

## Signature

`getEmails()` — returns `array`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Primarily used for testing to get information about emails sent during the request.




## Examples

<pre><code class='javascript'>// 1. Assert that exactly one email was sent during the action (in a test)
processSignup();
emails = getEmails();
assert(&quot;arrayLen(emails) eq 1&quot;);
assert(&quot;emails[1].to eq 'newuser@example.com'&quot;);
assert(&quot;emails[1].subject eq 'Welcome!'&quot;);

// 2. Inspect all emails sent during a request
emails = getEmails();
for (email in emails) {
	writeOutput(email.to &amp; &quot; — &quot; &amp; email.subject);
}

// 3. Return an empty array when no emails were sent
emails = getEmails();
// emails -&gt; []
</code></pre>
