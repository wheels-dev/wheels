/**
 * Re-export of `wheels.middleware.MiddlewareInterface` for the central interface catalog.
 *
 * The canonical interface lives at `wheels.middleware.MiddlewareInterface`.
 * This wrapper provides access via the `wheels.interfaces` namespace without
 * breaking existing `implements="wheels.middleware.MiddlewareInterface"` references.
 *
 * [section: Middleware]
 * [category: Interface]
 */
interface extends="wheels.middleware.MiddlewareInterface" {
}
