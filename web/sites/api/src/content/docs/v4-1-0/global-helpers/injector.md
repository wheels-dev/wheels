---
title: injector()
description: "Return a reference to the DI container for direct configuration."
sidebar:
  label: injector()
  order: 0
---

## Signature

`injector()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Return a reference to the DI container for direct configuration.




## Examples

<pre><code class='javascript'>// 1. Register a singleton service in `config/services.cfm` (one instance per app lifetime)
di = injector();
di.map(&quot;emailService&quot;).to(&quot;app.lib.EmailService&quot;).asSingleton();

// 2. Bind an interface name to a concrete implementation
di = injector();
di.bind(&quot;INotifier&quot;).to(&quot;app.lib.SlackNotifier&quot;).asSingleton();

// 3. Register a request-scoped service (one instance per HTTP request)
di = injector();
di.map(&quot;currentUser&quot;).to(&quot;app.lib.CurrentUserResolver&quot;).asRequestScoped();

// 4. Inspect or resolve at runtime
di = injector();
if (di.containsInstance(&quot;emailService&quot;)) {
    mailer = di.getInstance(&quot;emailService&quot;);
    mailer.send(to=&quot;user@example.com&quot;, subject=&quot;Welcome&quot;);
}
</code></pre>
