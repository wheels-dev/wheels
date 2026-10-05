// Test middleware with no init() of its own: it inherits InitFlagMiddleware's.
// A string-registered component like this must still have init() run.
component extends="wheels.tests._assets.middleware.InitFlagMiddleware" {
}
