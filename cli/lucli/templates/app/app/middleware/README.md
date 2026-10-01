# app/middleware/

Your own middleware components: request-level concerns that run before controllers, such as an auth check for `/api`, a tenant resolver, or request logging.

A middleware component implements `wheels.middleware.MiddlewareInterface`: one `handle(request, next)` method that returns the response string. Inspect the request, decide whether to call `next(request)`, and decide what to do with the response when it comes back.

```cfm
// app/middleware/RequestTimer.cfc
component implements="wheels.middleware.MiddlewareInterface" {
    public RequestTimer function init() {
        return this;
    }
    public string function handle(required struct request, required any next) {
        var started = GetTickCount();
        var response = arguments.next(arguments.request);
        writeLog(file = "requests", text = "#cgi.path_info# took #GetTickCount() - started#ms");
        return response;
    }
}
```

Register it in `config/settings.cfm` (all requests) or on a route scope (one subtree). A component registered by CFC path, such as `"app.middleware.RequestTimer"`, needs an `init()` that returns `this`.

See [Middleware Pipeline](https://guides.wheels.dev/v4-1-0/core-concepts/middleware-pipeline/) in the guides for registration, ordering and the built-in components.
