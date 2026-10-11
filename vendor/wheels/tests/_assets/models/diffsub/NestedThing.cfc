/**
 * A model in a subfolder of the model path, loaded as model("diffsub.NestedThing"), for
 * AutoMigratorDiffSpec's check that the all-models diff covers subfolders. Tableless.
 */
component extends="wheels.tests._assets.models.Model" {

	function config() {
		table(false);
	}

}
