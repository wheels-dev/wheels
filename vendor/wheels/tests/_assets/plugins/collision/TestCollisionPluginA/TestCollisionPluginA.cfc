component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public string function $CollidingMethod() mixin="controller" {
		return "FromPluginA";
	}

	public string function $UniqueToA() mixin="model" {
		return "OnlyA";
	}

}
