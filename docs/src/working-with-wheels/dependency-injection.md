# Dependency Injection

Wheels includes a built-in dependency injection (DI) container that manages service objects and their lifecycles. Register services once in `config/services.cfm`, then resolve them anywhere in your application with `service()` or declarative `inject()`.

## Registering Services

Create `config/services.cfm` to register your services at application startup:

```cfm
<cfscript>
// Get a reference to the DI container
var di = injector();

// Register a transient (new instance each time)
di.map("emailService").to("app.lib.EmailService");

// Register a singleton (one instance for the app lifetime)
di.map("cacheService").to("app.lib.CacheService").asSingleton();

// Register a request-scoped service (one instance per HTTP request)
di.map("currentUser").to("app.lib.CurrentUserService").asRequestScoped();

// Interface binding — semantic alias for map()
di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
</cfscript>
```

## Lifecycle Scopes

| Scope | Method | Behavior |
|-------|--------|----------|
| **Transient** | *(default)* | New instance every time `getInstance()` or `service()` is called |
| **Singleton** | `.asSingleton()` | One shared instance for the entire application lifetime |
| **Request** | `.asRequestScoped()` | One instance per HTTP request, automatically cleaned up |

### When to use each scope

- **Transient**: Stateless utilities, formatters, validators
- **Singleton**: Database connection pools, configuration, caches
- **Request**: Current user context, request-specific state, audit loggers

## Using service() in Controllers and Views

The `service()` global helper resolves a registered service by name:

```cfm
// In a controller action
function show() {
    var emailService = service("emailService");
    emailService.send(to=user.email, subject="Welcome!");
}
```

```cfm
<!--- In a view --->
<cfset var config = service("appConfig")>
<p>Version: #config.getVersion()#</p>
```

## Declarative inject() in Controllers

For services used across multiple actions, declare them in your controller's `config()`:

```cfm
component extends="Controller" {
    function config() {
        inject("emailService");
        // Or inject multiple at once:
        inject("emailService, cacheService, currentUser");

        // Other config...
        filters(through="authenticate");
    }

    function create() {
        // Services are available as this.serviceName
        this.emailService.sendWelcome(user);
        this.cacheService.invalidate("users");
    }
}
```

Injected services are resolved when the controller instance is created (per-request), so request-scoped services get fresh instances automatically.

## Interface Binding with bind()

Use `bind()` instead of `map()` when you want to emphasize that the name represents an abstraction:

```cfm
// In config/services.cfm
var di = injector();

// Bind an interface name to a concrete implementation
di.bind("IPaymentGateway").to("app.lib.StripeGateway").asSingleton();

// In production, swap the implementation without changing consumers
// di.bind("IPaymentGateway").to("app.lib.PayPalGateway").asSingleton();
```

`bind()` is functionally identical to `map()` — CFML has no formal interfaces, so this is semantic sugar for code clarity.

## Auto-Wiring

When a service's `init()` method has parameters whose names match registered service names, the container automatically resolves and injects them:

```cfm
// app/lib/OrderService.cfc
component {
    public OrderService function init(
        required any emailService,
        required any cacheService
    ) {
        variables.emailService = arguments.emailService;
        variables.cacheService = arguments.cacheService;
        return this;
    }
}
```

```cfm
// config/services.cfm
var di = injector();
di.map("emailService").to("app.lib.EmailService").asSingleton();
di.map("cacheService").to("app.lib.CacheService").asSingleton();
di.map("orderService").to("app.lib.OrderService").asSingleton();

// orderService.init() automatically receives emailService and cacheService
```

Auto-wiring is opt-in: it only activates when no explicit `initArguments` are passed to `getInstance()`. Parameters that don't match any registered mapping are skipped.

### Circular Dependency Protection

The container detects circular dependencies and throws `Wheels.DI.CircularDependency` with a clear message showing the resolution chain, rather than causing a stack overflow.

## Environment-Specific Services

Just like `config/settings.cfm`, you can create environment-specific service overrides:

```
config/
    services.cfm                    # Base registrations
    development/
        services.cfm                # Override for development
    testing/
        services.cfm                # Override for testing
    production/
        services.cfm                # Override for production
```

Environment-specific services are loaded after the base file, so they can override registrations:

```cfm
// config/testing/services.cfm
var di = injector();
di.bind("IPaymentGateway").to("app.lib.MockPaymentGateway").asSingleton();
di.map("emailService").to("app.lib.MockEmailService").asSingleton();
```

## Introspection API

The container provides methods to inspect its state:

```cfm
var di = injector();
di.getMappings();                    // struct of all name → componentPath mappings
di.containsInstance("emailService"); // true if registered
di.isSingleton("emailService");      // true if marked as singleton
di.isRequestScoped("currentUser");   // true if marked as request-scoped
```

## Examples

### Full Application Setup

```cfm
// config/services.cfm
<cfscript>
var di = injector();

// Infrastructure
di.map("mailer").to("app.lib.PostmarkMailer").asSingleton();
di.map("cache").to("app.lib.RedisCache").asSingleton();
di.map("logger").to("app.lib.AppLogger").asSingleton();

// Request-scoped
di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
di.map("auditLog").to("app.lib.AuditLogger").asRequestScoped();

// Business logic (auto-wired)
di.map("orderService").to("app.lib.OrderService");
di.map("invoiceService").to("app.lib.InvoiceService");
</cfscript>
```

```cfm
// app/controllers/Orders.cfc
component extends="Controller" {
    function config() {
        inject("orderService, currentUser");
        filters(through="authenticate");
    }

    function create() {
        var order = model("Order").create(params.order);
        this.orderService.processNewOrder(order, this.currentUser);
        redirectTo(route="order", key=order.id);
    }
}
```
