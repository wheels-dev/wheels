// Helpers extracted from run.cfm because BoxLang 1.5's bytecode generator
// crashes when compiling top-level functions / closures that wrap
// `new wheels.X(...)` in try/catch. Moving them into a CFC sidesteps it.
component output="false" {

    public struct function tryConstructCors() {
        var out = {threw: false, type: ""};
        try {
            CreateObject("component", "wheels.middleware.Cors").init(allowOrigins = "*", allowCredentials = true);
        } catch (any e) {
            out.threw = true;
            out.type = e.type;
        }
        return out;
    }

    public struct function tryRateLimiterStrategy(required string strategy) {
        var out = {threw: false, type: ""};
        try {
            CreateObject("component", "wheels.middleware.RateLimiter").init(maxRequests = 10, strategy = arguments.strategy);
        } catch (any e) {
            out.threw = true;
            out.type = e.type;
        }
        return out;
    }

    public struct function tryRateLimiterProxyStrategy(required string proxyStrategy) {
        var out = {threw: false, type: ""};
        try {
            CreateObject("component", "wheels.middleware.RateLimiter").init(maxRequests = 10, trustProxy = true, proxyStrategy = arguments.proxyStrategy);
        } catch (any e) {
            out.threw = true;
            out.type = e.type;
        }
        return out;
    }

    public struct function tryRateLimiterStorage(required string storage) {
        var out = {threw: false, type: ""};
        try {
            CreateObject("component", "wheels.middleware.RateLimiter").init(maxRequests = 10, storage = arguments.storage);
        } catch (any e) {
            out.threw = true;
            out.type = e.type;
        }
        return out;
    }
}
