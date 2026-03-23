/**
 * Interface for modern plugin service providers.
 *
 * Plugins that implement this interface opt into the ServiceProvider lifecycle
 * instead of the legacy mixin injection model. During application startup:
 *
 * 1. `register()` is called on each provider — bind services into the DI container.
 * 2. `boot()` is called on each provider after ALL providers have registered —
 *    configure routes, event listeners, or anything that depends on other services.
 *
 * [section: Plugins]
 * [category: Core]
 */
interface {

	/**
	 * Register service bindings into the DI container.
	 *
	 * Called once during application startup, before any provider's boot() method.
	 * Use this to bind interfaces to implementations, register singletons, and
	 * define factory closures. Do NOT resolve services here — other providers
	 * may not have registered yet.
	 *
	 * @container The Wheels DI container (Injector instance). Use map/bind/to to register services.
	 */
	public void function register(required any container);

	/**
	 * Boot the plugin after all providers have registered.
	 *
	 * Called once during application startup, after every provider's register()
	 * has completed. Safe to resolve services from the container here. Use this
	 * for runtime configuration: adding routes, registering event listeners,
	 * publishing config, etc.
	 *
	 * @app The Wheels application configuration struct (application.wheels).
	 */
	public void function boot(required struct app);

}
