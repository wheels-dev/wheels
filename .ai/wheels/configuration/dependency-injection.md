# Dependency Injection Container

## Quick Reference

### Registration (config/services.cfm)
```cfm
var di = injector();
di.map("name").to("dotted.component.Path");              // transient
di.map("name").to("dotted.component.Path").asSingleton(); // singleton
di.map("name").to("dotted.component.Path").asRequestScoped(); // per-request
di.bind("IName").to("dotted.component.Path");             // interface alias (= map)
```

### Resolution
```cfm
service("name");                         // global helper — resolves from container
injector();                              // returns the DI container reference
injector().getInstance("name");          // direct container resolution
injector().getInstance(name="x", initArguments={key: val}); // with explicit init args
```

### Controller inject()
```cfm
component extends="Controller" {
    function config() {
        inject("svcA, svcB");            // comma-delimited list
    }
    function myAction() {
        this.svcA.doWork();              // resolved per-request on this.*
    }
}
```

## Scopes

| Scope | Chained Method | Cache Location | Lifetime |
|-------|---------------|----------------|----------|
| Transient | *(none)* | No cache | Per-call |
| Singleton | `.asSingleton()` | `variables.singletons` | Application |
| Request | `.asRequestScoped()` | `request.$wheelsDICache` | Single HTTP request |

## Auto-Wiring

When `initArguments` is empty, the container inspects `init()` parameter names via `getMetaData()`. If a parameter name matches a registered mapping (`containsInstance(paramName)`), it auto-resolves and injects it.

**Precedence:** Explicit `initArguments` > auto-wired > plain `init()` with no args.

## Error Types

| Type | When |
|------|------|
| `Wheels.DI.NotInitialized` | `service()` or `injector()` called before app start |
| `Wheels.DI.ServiceNotFound` | `service("name")` where name is not registered |
| `Wheels.DI.CircularDependency` | Auto-wiring detects A→B→A cycle |
| `Wheels.Injector` | `to()` called without preceding `map()` |

## Introspection API

```cfm
di.containsInstance("name")   // boolean — mapping exists?
di.isSingleton("name")        // boolean
di.isRequestScoped("name")    // boolean
di.getMappings()               // struct {name: componentPath, ...}
```

## Environment Overrides

```
config/services.cfm                          # base
config/<environment>/services.cfm            # override (loaded after base)
```

## File Locations

| File | Purpose |
|------|---------|
| `vendor/wheels/Injector.cfc` | Container implementation |
| `vendor/wheels/Global.cfc` | `service()` and `injector()` helpers |
| `vendor/wheels/controller/services.cfc` | `inject()`, `injectedServices()`, `$resolveInjectedServices()` |
| `vendor/wheels/Controller.cfc` | Initializes `$class.services`, calls `$resolveInjectedServices()` |
| `vendor/wheels/events/onapplicationstart.cfc` | Loads `config/services.cfm` |
| `config/services.cfm` | User service registrations |

## Common Patterns

### Service with dependencies (auto-wired)
```cfm
// app/lib/OrderService.cfc — init params match registered names
component {
    public OrderService function init(required any emailService, required any logger) {
        variables.emailService = arguments.emailService;
        variables.logger = arguments.logger;
        return this;
    }
}

// config/services.cfm
di.map("emailService").to("app.lib.EmailService").asSingleton();
di.map("logger").to("app.lib.AppLogger").asSingleton();
di.map("orderService").to("app.lib.OrderService"); // auto-wires emailService + logger
```

### Testing with mock services
```cfm
// config/testing/services.cfm
var di = injector();
di.map("emailService").to("app.lib.MockEmailService").asSingleton();
```
