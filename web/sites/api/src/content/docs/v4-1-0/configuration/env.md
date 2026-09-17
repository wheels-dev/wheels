---
title: env()
description: "Returns the value of an environment variable. Checks application.env (loaded from .env files) first, then falls back to system environment variables (server.sys"
sidebar:
  label: env()
  order: 0
---

## Signature

`env()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns the value of an environment variable. Checks application.env (loaded from .env files) first, then falls back to system environment variables (server.system.environment). Returns the default if the variable is not found in either location.


named argument <code>default</code> is also accepted for backwards compatibility
with pre-rename callers.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The environment variable name to look up. |
| `defaultValue` | `any` | no | — | Value to return if the variable is not found. The legacy |

</div>

## Examples

<pre><code class='javascript'>// 1. Read a required environment variable
dbUrl = env(&quot;DATABASE_URL&quot;);
// dbUrl -&gt; &quot;postgres://user:pass@localhost/myapp&quot; (or &quot;&quot; if not set)

// 2. Provide a default when the variable may be absent
smtpHost = env(&quot;SMTP_HOST&quot;, &quot;localhost&quot;);
// smtpHost -&gt; &quot;localhost&quot; when SMTP_HOST is not defined in .env or system env

// 3. Guard application startup based on an environment variable
appSecret = env(&quot;APP_SECRET_KEY&quot;);
if (!Len(appSecret)) {
	throw(type=&quot;App.ConfigError&quot;, message=&quot;APP_SECRET_KEY must be set.&quot;);
}
</code></pre>
