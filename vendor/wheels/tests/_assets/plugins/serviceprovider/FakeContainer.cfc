/**
 * Minimal mock of the Wheels Injector's fluent API.
 * Used by pluginsSpec.cfc ServiceProvider tests to verify register()
 * is called without triggering the real DI container or colliding
 * with Lucee's built-in struct member functions (struct.map, etc.).
 */
component {

	public FakeContainer function init() {
		return this;
	}

	public FakeContainer function map(required string name) {
		return this;
	}

	public FakeContainer function mapInstance(required string name) {
		return this;
	}

	public FakeContainer function to(required string componentPath) {
		return this;
	}

	public FakeContainer function bind(required string name) {
		return this;
	}

	public FakeContainer function asSingleton() {
		return this;
	}

	public FakeContainer function asRequestScoped() {
		return this;
	}

}
