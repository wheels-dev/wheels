# DI Container Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

Register services in `config/services.cfm` (loaded at app start; environment overrides supported):

```cfm
local.di = injector();
local.di.map("emailService").to("app.lib.EmailService").asSingleton();
local.di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
local.di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
```

Resolve with `service("emailService")` anywhere, or `inject("emailService, currentUser")` in controller `config()`. Scopes: transient (default), `.asSingleton()`, `.asRequestScoped()`. Auto-wiring: `init()` params matching registered names are auto-resolved when no `initArguments` passed.

Construction that needs logic uses `.toFactory()` — bind a name to a closure that builds the instance (receives the `Injector`) and honors the chained lifecycle flag:

```cfm
local.di.map("jwtStrategy").toFactory(function(container) {
    return new wheels.auth.JwtStrategy(jwtService = new wheels.auth.JwtService(secretKey = env("JWT_SECRET")));
}).asSingleton();
// service("jwtStrategy") returns the factory's result — no .build() indirection
```
