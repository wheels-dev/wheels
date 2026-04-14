---
description: >-
  Complete reference for the lucee.json configuration file — all fields,
  defaults, and annotated examples for LuCLI-powered Wheels applications.
---

# lucee.json Reference

`lucee.json` is the single configuration file for LuCLI-powered Wheels applications. It replaces CommandBox's separate `box.json` and `server.json` files, combining server settings, JVM configuration, URL rewriting, and Lucee mappings into one declarative file.

## Location

Place `lucee.json` in your **project root** (the same directory as `app/`, `config/`, and `public/`):

```
myapp/
├── lucee.json          ← here
├── app/
├── config/
├── public/             ← webroot
├── tests/
└── vendor/
```

The CLI reads `lucee.json` to detect the server port, and LuCLI's embedded Lucee server uses it for startup configuration.

## Default File

Running `wheels new myapp` generates this `lucee.json`:

```json
{
  "name": "myapp",
  "version": "7.0.2.101",
  "port": 8080,
  "shutdownPort": 8081,
  "webroot": "./public",
  "openBrowser": true,
  "jvm": {
    "maxMemory": "512m",
    "minMemory": "128m"
  },
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "admin": {
    "enabled": true
  },
  "enableLucee": true,
  "enableREST": false,
  "monitoring": {
    "enabled": false,
    "jmx": {
      "port": 8082
    }
  },
  "configuration": {
    "datasources": {},
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
```

## Field Reference

### Top-Level Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | App name | Application identifier. Set to the name you pass to `wheels new`. |
| `version` | string | `"7.0.2.101"` | Lucee engine version to use. Determines which embedded Lucee runtime LuCLI starts. |
| `port` | number | `8080` | HTTP port for the development server. The CLI detects running servers by checking this port first. |
| `shutdownPort` | number | `port + 1` | Port used to send shutdown commands to the server. Always set to one above `port` during scaffolding. |
| `webroot` | string | `"./public"` | Relative path to the web-accessible directory. All HTTP requests are served from this directory. |
| `openBrowser` | boolean | `true` | Whether to automatically open a browser tab when the server starts via `wheels start`. |
| `enableLucee` | boolean | `true` | Enable Lucee-specific extensions and features. Should always be `true` for Wheels applications. |
| `enableREST` | boolean | `false` | Enable Lucee's built-in REST servlet. Not required for Wheels (which has its own routing). |

### jvm

JVM heap memory settings for the embedded Lucee server.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `jvm.maxMemory` | string | `"512m"` | Maximum heap size. Use `m` for megabytes, `g` for gigabytes. Increase for large applications or heavy query usage. |
| `jvm.minMemory` | string | `"128m"` | Initial heap size. Setting this closer to `maxMemory` reduces GC pauses during startup. |

**Example — larger application:**
```json
"jvm": {
  "maxMemory": "1g",
  "minMemory": "256m"
}
```

### urlRewrite

URL rewriting configuration for clean URLs (e.g., `/users/1` instead of `/index.cfm?controller=users&action=show&key=1`).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `urlRewrite.enabled` | boolean | `true` | Enable URL rewriting. Should always be `true` for Wheels. |
| `urlRewrite.routerFile` | string | `"index.cfm"` | The front-controller file that handles all requests. This is Wheels' entry point — don't change it. |

### admin

Lucee server administration panel settings.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `admin.enabled` | boolean | `true` | Enable the Lucee admin panel (accessible at `/lucee/admin/`). Disable in production for security. |

### monitoring

Server monitoring and JMX configuration.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `monitoring.enabled` | boolean | `false` | Enable server monitoring. When enabled, exposes JMX metrics for external monitoring tools. |
| `monitoring.jmx.port` | number | `8082` | JMX remote port for connecting monitoring tools (e.g., JConsole, VisualVM). Only used when monitoring is enabled. |

**Example — enable monitoring:**
```json
"monitoring": {
  "enabled": true,
  "jmx": {
    "port": 9090
  }
}
```

### configuration

Lucee server configuration for datasources and component mappings.

#### configuration.datasources

Datasource definitions that Lucee registers at startup. By default this is empty — Wheels applications typically configure datasources in `config/app.cfm` or `config/settings.cfm` using `.env` variables.

When you scaffold with `--setup-h2` or the default SQLite option, the datasource configuration is written to `config/app.cfm` rather than `lucee.json`. However, you can define datasources here for Lucee-level registration:

```json
"datasources": {
  "myapp": {
    "class": "org.h2.Driver",
    "connectionString": "jdbc:h2:file:./db/h2/myapp;MODE=MySQL",
    "username": "sa",
    "password": ""
  }
}
```

#### configuration.mappings

Lucee component mappings that allow CFML to resolve component paths. These are the equivalent of `this.mappings` in `Application.cfc`, but defined declaratively.

| Mapping | Default Value | Purpose |
|---------|--------------|---------|
| `/wheels` | `"../vendor/wheels"` | Wheels framework core. Models extend `"Model"`, controllers extend `"Controller"` — both resolve through this mapping. |
| `/app` | `"../app"` | Application code (models, controllers, views, events, etc.). |
| `/config` | `"../config"` | Configuration files (`settings.cfm`, `routes.cfm`, `app.cfm`). |
| `/tests` | `"../tests"` | Test specs and test infrastructure. |

All paths are **relative to the webroot** (`./public`), which is why they use `../` to navigate up one directory.

**Adding custom mappings:**
```json
"mappings": {
  "/wheels": "../vendor/wheels",
  "/app": "../app",
  "/config": "../config",
  "/tests": "../tests",
  "/lib": "../lib",
  "/shared": "../../shared-components"
}
```

## Annotated Examples

### Minimal Configuration

The smallest valid `lucee.json` for a Wheels project:

```json
{
  "name": "myapp",
  "port": 8080,
  "webroot": "./public",
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "configuration": {
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
```

Fields like `version`, `jvm`, `admin`, and `monitoring` use sensible defaults when omitted.

### Production-Hardened Configuration

A configuration suitable for production deployment:

```json
{
  "name": "myapp",
  "version": "7.0.2.101",
  "port": 8080,
  "shutdownPort": 8081,
  "webroot": "./public",
  "openBrowser": false,
  "jvm": {
    "maxMemory": "1g",
    "minMemory": "512m"
  },
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "admin": {
    "enabled": false
  },
  "enableLucee": true,
  "enableREST": false,
  "monitoring": {
    "enabled": true,
    "jmx": {
      "port": 9090
    }
  },
  "configuration": {
    "datasources": {},
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config"
    }
  }
}
```

Key differences from development:
- `openBrowser`: `false` — no browser popup on headless servers
- `admin.enabled`: `false` — Lucee admin panel disabled for security
- `jvm.maxMemory`: `"1g"` — more memory for production workloads
- `jvm.minMemory`: `"512m"` — pre-allocate to reduce GC pressure
- `monitoring.enabled`: `true` — expose JMX metrics
- `/tests` mapping removed — no test code in production

### API-Only Application

For a Wheels application serving only JSON APIs:

```json
{
  "name": "myapi",
  "version": "7.0.2.101",
  "port": 3000,
  "shutdownPort": 3001,
  "webroot": "./public",
  "openBrowser": false,
  "jvm": {
    "maxMemory": "768m",
    "minMemory": "256m"
  },
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "admin": {
    "enabled": false
  },
  "enableLucee": true,
  "enableREST": false,
  "monitoring": {
    "enabled": true,
    "jmx": {
      "port": 3002
    }
  },
  "configuration": {
    "datasources": {},
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
```

### Custom Port with H2 Database

For local development with a non-default port and H2:

```json
{
  "name": "blog",
  "version": "7.0.2.101",
  "port": 3000,
  "shutdownPort": 3001,
  "webroot": "./public",
  "openBrowser": true,
  "jvm": {
    "maxMemory": "512m",
    "minMemory": "128m"
  },
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "admin": {
    "enabled": true
  },
  "enableLucee": true,
  "enableREST": false,
  "monitoring": {
    "enabled": false
  },
  "configuration": {
    "datasources": {
      "blog": {
        "class": "org.h2.Driver",
        "connectionString": "jdbc:h2:file:./db/h2/blog;MODE=MySQL",
        "username": "sa",
        "password": ""
      },
      "wheelstestdb": {
        "class": "org.h2.Driver",
        "connectionString": "jdbc:h2:file:./db/h2/wheelstestdb;MODE=MySQL",
        "username": "sa",
        "password": ""
      }
    },
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
```

## How the CLI Uses lucee.json

### Port Detection

When you run commands that need a running server (e.g., `wheels test`, `wheels reload`, `wheels migrate`), the CLI detects the server port using this priority:

1. **`lucee.json`** — reads the `port` field and checks if that port is open
2. **`.env`** — looks for a `PORT=` variable
3. **Common ports** — tries 8080, 60000, 3000, 8500 in order

### Project Scaffolding

`wheels new myapp` generates `lucee.json` from the template at `cli/lucli/templates/app/lucee.json`. Template variables (`{{appName}}`, `{{port}}`, etc.) are replaced with values from the command options:

| Template Variable | Source | Default |
|-------------------|--------|---------|
| `{{appName}}` | First argument to `wheels new` | (required) |
| `{{port}}` | `--port` option | `8080` |
| `{{shutdownPort}}` | Computed as `port + 1` | `8081` |
| `{{openBrowser}}` | `--no-open-browser` flag | `true` |

### Server Start

`wheels start` delegates to LuCLI's embedded Lucee server, which reads `lucee.json` for:
- Port binding (`port`, `shutdownPort`)
- Webroot path (`webroot`)
- JVM configuration (`jvm`)
- Component mappings (`configuration.mappings`)
- Datasource registration (`configuration.datasources`)

## Comparison with CommandBox

If you're migrating from CommandBox, here's how the fields map:

| CommandBox | lucee.json | Notes |
|------------|-----------|-------|
| `server.json → web.http.port` | `port` | Flat field instead of nested |
| `server.json → web.webroot` | `webroot` | Relative path, not absolute |
| `server.json → app.cfengine` | `version` | Always Lucee (no Adobe CF option) |
| `server.json → web.rewrites.enable` | `urlRewrite.enabled` | Same concept |
| `server.json → jvm.heapSize` | `jvm.maxMemory` | Split into min/max |
| `box.json → name` | `name` | Same purpose |
| `Application.cfc → this.mappings` | `configuration.mappings` | Declarative in JSON |
| CommandBox admin panel | `admin.enabled` | Single boolean toggle |

For a full migration guide, see [Migrating from CommandBox](migration-from-commandbox.md).

## Environment Overrides

Currently, `lucee.json` does not support environment-specific variants (e.g., `lucee-production.json`). For environment-specific configuration:

- Use **`.env` files** for values that change per environment (database credentials, ports, feature flags). See [Configuration Management](../configuration.md).
- Use **`config/settings.cfm`** and **`config/{environment}/settings.cfm`** for Wheels-level settings.
- Use **`lucee.json`** for server-level settings that are the same across environments.

> **Tip**: Keep `lucee.json` committed to version control. Move secrets and environment-specific values to `.env` files (which should be gitignored).

## Troubleshooting

### Server won't start

Verify `lucee.json` is valid JSON:
```bash
python3 -c "import json; json.load(open('lucee.json'))"
```

Check that the `port` isn't already in use:
```bash
lsof -i :8080
```

### Mappings not resolving

Ensure paths are relative to the **webroot**, not the project root. Since `webroot` is `./public`, a mapping of `"../vendor/wheels"` resolves to `<project-root>/vendor/wheels`.

### CLI can't detect running server

The CLI checks if the port in `lucee.json` is open. If your server is running on a different port (e.g., you changed it after starting), either:
- Restart the server so it picks up the new port
- Set `PORT=<number>` in your `.env` file as a fallback
