component mixin="global" {

	function init() {
		this.version = "99.9.9";
		return this;
	}

	public string function $IntFullManifestMethod() {
		return "full-manifest-works";
	}

}
