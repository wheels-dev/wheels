/**
 * A WheelsTest whose repository root is set by the spec, so $requireRepoPath() can be
 * exercised against a directory that is not the framework repository.
 */
component extends="wheels.WheelsTest" {

	public any function setProbeRoot(required string root) {
		variables.probeRoot = arguments.root;
		return this;
	}

	public string function $frameworkRepoRoot() {
		return variables.probeRoot;
	}

}
