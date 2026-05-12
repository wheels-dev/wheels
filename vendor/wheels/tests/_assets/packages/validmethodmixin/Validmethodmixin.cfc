component {
	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	// Follows the manifest default (controller)
	public string function $validmethodmixinControllerHelper() {
		return "on-controller";
	}

	// Per-method override to model target
	public string function $validmethodmixinModelHelper() mixin="model" {
		return "on-model";
	}

	// Explicit opt-out of mixin injection while still callable via getPackage()
	public string function $validmethodmixinInternal() mixin="none" {
		return "internal";
	}
}
