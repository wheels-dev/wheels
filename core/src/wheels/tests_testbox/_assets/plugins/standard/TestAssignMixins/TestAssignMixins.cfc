component {
	function init() {
		this.version = "99.9.9";
		return this;
	}

	public void function $MixinForControllers() mixin="controller"{

	}

	public void function $MixinForModels() mixin="model" {

	}

	public void function $MixinForModelsAndContollers() mixin="model,controller" {

	}

	public void function $MixinForDispatch() mixin="dispatch" {

	}
}