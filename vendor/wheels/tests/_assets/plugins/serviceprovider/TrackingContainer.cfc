/**
 * Injector stand-in that records mapInstance/to bindings and supports
 * snapshot/restore so hardener S7 can prove a failed boot() leaves no residue.
 */
component {

	public TrackingContainer function init() {
		variables.mappings = {};
		variables.currentMapping = "";
		return this;
	}

	public TrackingContainer function map(required string name) {
		variables.currentMapping = arguments.name;
		return this;
	}

	public TrackingContainer function mapInstance(required string name) {
		return map(argumentCollection = arguments);
	}

	public TrackingContainer function to(required string componentPath) {
		if (Len(variables.currentMapping)) {
			variables.mappings[variables.currentMapping] = arguments.componentPath;
			variables.currentMapping = "";
		}
		return this;
	}

	public TrackingContainer function bind(required string name) {
		return map(argumentCollection = arguments);
	}

	public TrackingContainer function asSingleton() {
		return this;
	}

	public TrackingContainer function asRequestScoped() {
		return this;
	}

	public boolean function containsInstance(required string name) {
		return StructKeyExists(variables.mappings, arguments.name);
	}

	public struct function getMappings() {
		return Duplicate(variables.mappings);
	}

	public struct function $snapshotBindings() {
		return {mappings = Duplicate(variables.mappings)};
	}

	public void function $restoreBindings(required struct snapshot) {
		variables.mappings = StructKeyExists(arguments.snapshot, "mappings")
			? Duplicate(arguments.snapshot.mappings)
			: {};
	}

}
