component {
	function init() {
		this.version = "99.9.9";
		return this;
	}

	public string function URLFor() {
		local.result = core.URLFor(argumentCollection = arguments);
		local.result &= Find("?", local.result) ? "&urlfor01" : "?urlfor01";
		return local.result;
	}

	public any function onMissingMethod() {
		return core.onMissingMethod(argumentCollection = arguments);
	}

	public string function $$pluginOnlyMethod() {
		return "$$returnValue";
	}

	public string function singularize() {
		return "$$completelyOverridden";
	}

	public string function pluralize() {
		corePluralize = core.pluralize;
		return corePluralize(argumentCollection = arguments);
	}

	function $helper01() {
		return $helper011();
	}

	function $helper01ConditionalCheck() {
		return false;
	}

	function $helper011() {
		return "$helper011Responding";
	}

	function includePartial() {
		return core.includePartial(argumentCollection = arguments);
	}
}