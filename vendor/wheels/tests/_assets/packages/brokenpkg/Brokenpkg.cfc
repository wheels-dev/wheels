component {
	public any function init() {
		throw(type="Wheels.TestBrokenPackage", message="Intentionally broken for testing");
		return this;
	}
}
