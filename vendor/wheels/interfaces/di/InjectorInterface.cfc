/**
 * Contract for the Wheels DI (dependency injection) container.
 *
 * The default implementation is `wheels.Injector`. This is one of only two
 * components that CAN use `implements=` for compile-time enforcement (the
 * other being `EventMethods`).
 *
 * All methods return the Injector instance to support fluent chaining:
 * `injector.map("svc").to("app.lib.Svc").asSingleton()`
 *
 * [section: DI Container]
 * [category: Interface]
 */
interface {

	/**
	 * Initialize the injector with a bindings file.
	 *
	 * @binderPath Dot-delimited path to the bindings CFC (e.g., "wheels.Bindings").
	 * @return The initialized Injector.
	 */
	public Injector function init(required string binderPath);

	/**
	 * Begin a mapping definition. Follow with `.to()` and optional scope methods.
	 * Use `mapInstance()` instead if the name collides with a CFML built-in (e.g., "map").
	 *
	 * @name Service name to register.
	 * @return The Injector (for chaining).
	 */
	public Injector function map(required string name);

	/**
	 * Alias for `map()` that avoids collisions with CFML's built-in `map()` function.
	 *
	 * @name Service name to register.
	 * @return The Injector (for chaining).
	 */
	public Injector function mapInstance(required string name);

	/**
	 * Set the component path for the current mapping.
	 *
	 * @componentPath Dot-delimited path to the implementation CFC.
	 * @return The Injector (for chaining).
	 */
	public Injector function to(required string componentPath);

	/**
	 * Semantic alias for `map()`. Reads better for interface-to-implementation bindings:
	 * `bind("INotifier").to("app.lib.SlackNotifier")`
	 *
	 * @name Interface or service name to register.
	 * @return The Injector (for chaining).
	 */
	public Injector function bind(required string name);

	/**
	 * Resolve and return an instance for the given service name.
	 *
	 * @name The registered service name to resolve.
	 * @initArguments Struct of arguments to pass to the component's init().
	 * @return The resolved component instance.
	 */
	public any function getInstance(required string name, struct initArguments);

	/**
	 * Check whether a mapping exists for the given name.
	 *
	 * @name Service name to check.
	 * @return True if a mapping exists.
	 */
	public boolean function containsInstance(required string name);

	/**
	 * Mark the current mapping as a singleton (one instance per app lifecycle).
	 *
	 * @return The Injector (for chaining).
	 */
	public Injector function asSingleton();

	/**
	 * Mark the current mapping as request-scoped (one instance per HTTP request).
	 *
	 * @return The Injector (for chaining).
	 */
	public Injector function asRequestScoped();

	/**
	 * Return all registered mappings as a struct.
	 *
	 * @return Struct where keys are service names and values are mapping metadata.
	 */
	public struct function getMappings();

	/**
	 * Check whether a mapping is configured as singleton.
	 *
	 * @name Service name to check.
	 * @return True if the mapping is a singleton.
	 */
	public boolean function isSingleton(required string name);

	/**
	 * Check whether a mapping is configured as request-scoped.
	 *
	 * @name Service name to check.
	 * @return True if the mapping is request-scoped.
	 */
	public boolean function isRequestScoped(required string name);

}
