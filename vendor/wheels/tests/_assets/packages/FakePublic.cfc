component extends="wheels.Public" {

	public FakePublic function init(array packages = []) {
		variables.fakePackages = arguments.packages;
		return this;
	}

	public struct function $loadRegistryPackages(any registry = "") {
		return {packages: variables.fakePackages, error: ""};
	}
}
