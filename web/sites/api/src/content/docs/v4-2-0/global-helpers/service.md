---
title: service()
description: "Resolve a DI-registered service by name."
sidebar:
  label: service()
  order: 0
---

## Signature

`service()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Resolve a DI-registered service by name.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The registered service name to resolve. |

</div>

## Examples

<pre><code class='javascript'>// 1. Resolve a registered service and call a method on it
mailer = service(&quot;MailerService&quot;);
mailer.send(to=&quot;user@example.com&quot;, subject=&quot;Welcome!&quot;);

// 2. Resolve a payment gateway service and process a charge
gateway = service(&quot;PaymentGateway&quot;);
result = gateway.charge(amount=params.amount, token=params.stripeToken);

// 3. Use a service in a model callback to send a notification
component extends=&quot;Model&quot; {
    function config() {
        afterCreate(method=&quot;notifyAdmin&quot;);
    }

    private function notifyAdmin() {
        notifier = service(&quot;NotificationService&quot;);
        notifier.notify(event=&quot;userCreated&quot;, userId=this.id);
    }
}
</code></pre>
