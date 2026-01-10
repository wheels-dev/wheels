component {
	function init() {
		this.version = "99.9.9";
		return this;
	}

	public string function URLFor() {
		local.result = core.URLFor(argumentCollection = arguments);
		local.result &= Find("?", local.result) ? "&urlfor02" : "?urlfor02";
		return local.result;
	}

	public any function onMissingMethod() {
		return core.onMissingMethod(argumentCollection = arguments);
	}
}