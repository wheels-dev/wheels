# wheels-sentry

A Wheels plugin for [Sentry](https://sentry.io) error tracking. Provides automatic SDK initialization, controller mixin methods, configurable scope capture, and breadcrumb support.

## Requirements

- Wheels 3.0+
- Lucee 5+ or Adobe ColdFusion 2018+

## Installation

Copy the `sentry` directory into your `plugins/` folder. The plugin auto-initializes on application start.

### Wheels settings to prevent plugin directory cleanup

```cfml
// config/settings.cfm
set(overwritePlugins=false);
set(deletePluginDirectories=false);
```

## Configuration

All settings are configured via `set()` in `config/settings.cfm`.

### Required

```cfml
set(sentryDSN="https://your-key@o123.ingest.us.sentry.io/456");
```

The DSN can also be read from the `SENTRY_DSN` Java system environment variable as a fallback.

### Scope Settings

The plugin controls what data is included in Sentry events. Settings are split into two groups: non-sensitive data (on by default) and PII/sensitive data (off by default).

| Setting | Default | Description |
|---|---|---|
| `sentryDSN` | `""` | **Required.** Your Sentry DSN. |
| `sentrySendDefaultPii` | `false` | Master toggle for PII. When `true`, enables `includeUser`, `includeSession`, and `includeCookies`. |
| `sentryIncludeHeaders` | `true` | Include HTTP request headers. |
| `sentryIncludeServerContext` | `true` | Include server name, port, remote addr, http host. |
| `sentryIncludeUser` | follows `sentrySendDefaultPii` | Include user context set via `sentrySetUser()`. |
| `sentryIncludeSession` | follows `sentrySendDefaultPii` | Include session scope data. |
| `sentryIncludeCookies` | follows `sentrySendDefaultPii` | Include cookie data in request context. |

Individual PII settings override `sentrySendDefaultPii`. For example, to enable only user context but not session or cookies:

```cfml
set(sentrySendDefaultPii=false);
set(sentryIncludeUser=true);
```

### What's always included (not configurable)

- Exception type, message, and CFML stack trace with source context
- Request URL and HTTP method
- Tags: `wheels.controller`, `wheels.action`, `cfml.engine`, `cfml.framework`, `wheels.environment`
- Breadcrumbs added during the request
- App context: environment, release, Wheels environment
- Server name

### Environment and release detection

- **Environment**: Read from `application.wheels.environment` (e.g., `production`, `development`)
- **Release**: Read from the `APP_VERSION` Java system environment variable, or `"unknown"`

## Usage

### Capturing exceptions in controllers

The plugin adds mixin methods to all controllers:

```cfml
// In any controller action
function show() {
    try {
        // risky operation
    } catch (any e) {
        sentryCapture(e);
        // or with extra data:
        sentryCapture(exception=e, level="warning", additionalData={orderId: params.key});
    }
}
```

### Sending messages

```cfml
sentryMessage("Payment processed for order #params.key#", "info");
```

### Setting user context

The plugin does **not** read user identity from the session automatically. This keeps it generic across applications. To attach user identity, call `sentrySetUser()` in a before filter:

```cfml
// app/controllers/Controller.cfc
component extends="wheels.Controller" {

    function config() {
        filters(through="setSentryUser");
    }

    private function setSentryUser() {
        if (structKeyExists(session, "currentUser")) {
            sentrySetUser({
                id: session.currentUser.id,
                email: session.currentUser.email,
                username: session.currentUser.name
            });
        }
    }
}
```

The struct passed to `sentrySetUser()` accepts any keys supported by Sentry's [user context](https://develop.sentry.dev/sdk/event-payloads/user/): `id`, `email`, `username`, `ip_address`, etc.

### Adding breadcrumbs

Breadcrumbs are included in the next captured event:

```cfml
sentryAddBreadcrumb("Loaded order #params.key#", "data");
sentryAddBreadcrumb("Checking inventory", "logic", {warehouse: "east"});
```

### Capturing errors in `onerror.cfm`

For unhandled errors that reach the Wheels error handler (production mode), add Sentry capture to `app/events/onerror.cfm`:

```cfml
<cfscript>
try {
    if (structKeyExists(application, "sentry") && structKeyExists(local, "exception")) {
        application.sentry.captureException(
            exception: local.exception,
            level: "error",
            useThread: false,
            showJavaStackTrace: true
        );
    }
} catch (any sentryError) {
    writeLog(text="Sentry capture failed: #sentryError.message#", type="error", file="application");
}
</cfscript>
```

Note: `useThread: false` is recommended in error handlers because threads may be killed during shutdown.

## Levels

Sentry levels: `fatal`, `error`, `warning`, `info`, `debug`

## DSN Formats

Both modern and legacy Sentry DSN formats are supported:

```
Modern:  https://{PUBLIC_KEY}@{HOST}/{PROJECT_ID}
Legacy:  https://{PUBLIC_KEY}:{SECRET_KEY}@{HOST}/{PROJECT_ID}
```

## License

MIT
