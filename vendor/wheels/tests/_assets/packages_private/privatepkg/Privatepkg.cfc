component {
	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	public string function $publicHelper() {
		return "public-reached";
	}

	private string function $privateHelper() {
		return "private-must-not-leak";
	}
}
