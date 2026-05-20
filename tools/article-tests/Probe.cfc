/**
 * Minimal middleware used to observe pipeline ordering and short-circuit
 * behavior in the article test harness.
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

    public Probe function init(required string label, required struct trail) {
        variables.label = arguments.label;
        variables.trail = arguments.trail;
        return this;
    }

    public string function handle(required struct request, required any next) {
        ArrayAppend(variables.trail.seen, variables.label);
        return arguments.next(arguments.request);
    }
}
