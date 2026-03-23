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
 * ## Available Framework Services
 *
 * The following services are registered by the framework before plugins load
 * and can be resolved during `boot()` via the container passed in `register()`:
 *
 * | Name           | Component Path              | Description                              |
 * |----------------|-----------------------------|------------------------------------------|
 * | `global`       | `wheels.Global`             | Core framework helpers and utilities      |
 * | `eventmethods` | `wheels.events.EventMethods`| Application lifecycle event handlers      |
 * | `ViewObj`      | `wheels.view`               | View rendering engine                     |
 *
 * In addition, any services registered in the application's `config/services.cfm`
 * are available, since that file is loaded before plugins.
 *
 * ## Resolving Services in boot()
 *
 * Store the container reference from `register()` and use it in `boot()`:
 *
 * ```
 * component implements="wheels.ServiceProviderInterface" {
 *     function init() {
 *         this.container = javacast("null", "");
 *         return this;
 *     }
 *     public void function register(required any container) {
 *         this.container = arguments.container;
 *         arguments.container.map("myService").to("app.lib.MyService").asSingleton();
 *     }
 *     public void function boot(required struct app) {
 *         var svc = this.container.getInstance("myService");
 *         svc.configure(app.environment);
 *     }
 * }
 * ```
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
	 * has completed and application `config/services.cfm` has been loaded.
	 * Safe to resolve services from the container here — both framework services
	 * and services registered by other providers are available.
	 *
	 * Use this for runtime configuration: resolving dependencies, configuring
	 * services based on the app environment, registering event listeners, etc.
	 *
	 * @app The Wheels application configuration struct (settings, environment, etc.)
	 */
	public void function boot(required struct app);

}
