component {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public string function $CollidingMethod() mixin="controller" {
		return "FromPluginB";
	}

	public string function $UniqueToB() mixin="model" {
		return "OnlyB";
	}

}
